locals {
  prefix = join("-", compact([var.name, var.environment, var.suffix]))
}

data "aws_vpc" "selected" {
  id      = var.vpc_id != "" ? var.vpc_id : null
  default = var.vpc_id == "" ? true : null
}

# A AZ é fixa (padrão: <região>a). O volume de dados existe numa AZ só: se a escolha da subnet variasse
# (ex.: subnet nova na VPC), a instância iria para outra AZ e o volume não poderia mais ser anexado.
locals {
  availability_zone = var.availability_zone != "" ? var.availability_zone : "${var.aws_region}a"
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "availability-zone"
    values = [local.availability_zone]
  }
}

locals {
  subnet_id = var.subnet_id != "" ? var.subnet_id : sort(data.aws_subnets.selected.ids)[0]
}

data "aws_subnet" "selected" {
  id = local.subnet_id
}

# Arquitetura da AMI: o nome da imagem Canonical usa amd64/arm64 (x86_64 e arm64 na variável).
locals {
  ami_arch = var.architecture == "arm64" ? "arm64" : "amd64"
}

# Sem ami_id fixo, usa a mais recente da Canonical. Só vale na criação: ver ignore_changes da instância.
data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-${local.ami_arch}-server-*"]
  }
}

# Entrada totalmente bloqueada (sem blocos ingress); saída livre.
# Acesso à máquina apenas via SSM Session Manager.
resource "aws_security_group" "this" {
  name        = local.prefix
  description = "Sem entrada; saida livre"
  vpc_id      = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = local.prefix, Purpose = "Security group da instancia: sem entrada, saida livre" }

  # Regras de entrada são ajustadas manualmente por ambiente: o Terraform cria o SG sem
  # entrada, mas não gera drift nem remove o que for adicionado depois.
  lifecycle {
    ignore_changes = [ingress]
  }
}

resource "aws_secretsmanager_secret" "env" {
  name                    = "${local.prefix}-env"
  description             = "Conteudo integral do arquivo de environments (valor cadastrado manualmente)"
  recovery_window_in_days = 30

  tags = { Name = "${local.prefix}-env", Purpose = "Conteudo do arquivo de environments da aplicacao" }

  # Protegido: so remove manualmente (ver infra-down.sh).
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.prefix
  assume_role_policy = data.aws_iam_policy_document.assume.json

  tags = { Name = local.prefix, Purpose = "Role da instancia: acesso via SSM e leitura do secret de environments" }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "read_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.env.arn]
  }
}

# Saída completa dos comandos do deploy.sh (setup/deploy/pins): a resposta da API do SSM corta em ~24 KB.
resource "aws_cloudwatch_log_group" "ssm" {
  name              = "/${local.prefix}/ssm"
  retention_in_days = var.ssm_log_retention_days

  tags = { Name = "${local.prefix}-ssm", Purpose = "Saida dos comandos enviados pelo deploy.sh via SSM" }
}

data "aws_iam_policy_document" "ssm_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
    resources = ["${aws_cloudwatch_log_group.ssm.arn}:*"]
  }
}

resource "aws_iam_role_policy" "ssm_logs" {
  name   = "write-ssm-logs"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.ssm_logs.json
}

resource "aws_iam_role_policy" "read_secret" {
  name   = "read-env-secret"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.read_secret.json
}

resource "aws_iam_instance_profile" "this" {
  name = local.prefix
  role = aws_iam_role.this.name

  tags = { Name = local.prefix, Purpose = "Instance profile da instancia" }
}

resource "aws_ebs_volume" "data" {
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name    = "${local.prefix}-data"
    Purpose = "Dados persistentes montados em /ext-vol"
    Backup  = "daily-${local.prefix}" # alvo da policy de snapshots (DLM)
  }

  # Protegido: so remove manualmente (ver infra-down.sh).
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type          = var.instance_type
  subnet_id              = local.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    data_volume_id = replace(aws_ebs_volume.data.id, "-", "")
    swap_size_gb   = var.swap_size_gb
  })

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = { Name = local.prefix, Purpose = "Servidor da aplicacao (Ubuntu 24.04 LTS)" }

  # A AMI é escolhida na criação. Sem isto, cada release da Canonical (busca "mais recente") recriaria a
  # instância no próximo up. Para trocar de AMI numa instância existente: terraform apply -replace.
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.this.id

  # No destroy, so some do state: o EC2 ao terminar solta o volume, que sobrevive com os dados.
  skip_destroy = true
}

resource "aws_eip" "this" {
  domain = "vpc"
  tags   = { Name = local.prefix, Purpose = "IP fixo publico da instancia" }

  # Protegido: o DNS dos dominios aponta para ele. O down solta so a associacao; remove no purge.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}

# Falha de status do hardware/SO da instância (não depende de agente). Sem alarm_sns_topic_arn, o alarme
# existe mas não notifica ninguém: defina o destino no terraform.tfvars.
resource "aws_cloudwatch_metric_alarm" "status_check" {
  alarm_name          = "${local.prefix}-status-check"
  alarm_description   = "Falha no status check da instancia ${local.prefix}"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed"
  dimensions          = { InstanceId = aws_instance.this.id }
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_sns_topic_arn == "" ? [] : [var.alarm_sns_topic_arn]

  tags = { Name = "${local.prefix}-status-check", Purpose = "Alarme de falha de status da instancia" }
}

# Backup diario do volume de dados. Os snapshots sao independentes do Terraform:
# nem o infra-down.sh nem a remocao do volume os apagam.
data "aws_iam_policy_document" "dlm_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm" {
  name               = "${local.prefix}-dlm"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume.json

  tags = { Name = "${local.prefix}-dlm", Purpose = "Role do DLM para criar snapshots diarios do volume de dados" }
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "data" {
  description        = "Snapshot diario do volume de dados ${local.prefix}"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]
    target_tags    = { Backup = "daily-${local.prefix}" }

    schedule {
      name = "diario"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"] # UTC = 00:00 em Sao Paulo
      }

      retain_rule {
        count = var.backup_retention_days
      }

      tags_to_add = {
        Name    = "${local.prefix}-data-snapshot"
        Purpose = "Backup diario do volume de dados"
      }
    }
  }

  tags = { Name = "${local.prefix}-data-backup", Purpose = "Policy de backup diario do volume de dados" }
}

# Portas do HTTPS público (só com https_enabled). Regras à parte: o bloco ingress do SG segue ignorado (ver acima).
resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = var.https_enabled ? toset(["80", "443"]) : toset([])

  security_group_id = aws_security_group.this.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  description       = "HTTPS publico (${each.value})"

  tags = { Name = "${local.prefix}-https-${each.value}", Purpose = "Entrada HTTPS publica (Let's Encrypt)" }
}

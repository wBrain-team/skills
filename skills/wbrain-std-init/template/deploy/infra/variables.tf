variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "sa-east-1"
}

variable "name" {
  description = "Nome do projeto: prefixo dos recursos; definido em deploy/config/config.yaml"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (ex.: prod, staging); definido em deploy/config/config.yaml"
  type        = string
}

variable "suffix" {
  description = "Sufixo opcional dos nomes (<name>-<environment>-<suffix>); definido em deploy/config/config.yaml"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Tipo da instância; deve ser compatível com a architecture (ex.: t3 para x86_64, t4g para arm64)"
  type        = string
  default     = "t3.small"
}

variable "architecture" {
  description = "Arquitetura da AMI e da instância: x86_64 ou arm64"
  type        = string
  default     = "x86_64"

  validation {
    condition     = contains(["x86_64", "arm64"], var.architecture)
    error_message = "architecture deve ser x86_64 ou arm64."
  }
}

variable "alarm_sns_topic_arn" {
  description = "Tópico SNS que recebe o alarme de falha de status da instância. Vazio = alarme sem notificação"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI fixa (ex.: ami-0123...). Vazio = mais recente da Canonical na criação. Ignorada depois da criação."
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Tamanho do volume raiz (GB)"
  type        = number
  default     = 20
}

variable "data_volume_size" {
  description = "Tamanho do volume de dados persistentes montado em /ext-vol (GB)"
  type        = number
  default     = 30
}

variable "swap_size_gb" {
  description = "Tamanho do swap em GB, criado como arquivo no volume raiz no primeiro boot (0 desativa)"
  type        = number
  default     = 4

  validation {
    condition     = var.swap_size_gb >= 0 && var.swap_size_gb == floor(var.swap_size_gb)
    error_message = "swap_size_gb deve ser um inteiro >= 0."
  }
}

variable "availability_zone" {
  description = "AZ da instância e do volume de dados. Vazio = <aws_region>a. Mudar depois da criação exige mover o volume (snapshot)"
  type        = string
  default     = ""
}

variable "ssm_log_retention_days" {
  description = "Dias de retenção no CloudWatch da saída dos comandos do deploy.sh"
  type        = number
  default     = 30
}

variable "vpc_id" {
  description = "VPC do security group. Vazio = VPC default"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet da instância (na availability_zone). Vazio = primeira subnet da VPC nessa AZ"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "backup_retention_days" {
  description = "Quantos snapshots diarios do volume de dados manter"
  type        = number
  default     = 7
}

# HTTPS público opcional (https.enabled no config.yaml): abre 80 (desafio HTTP-01 e redirect) e 443 no SG.
variable "https_enabled" {
  description = "Abre as portas 80 e 443 para o proxy HTTPS (Let's Encrypt)"
  type        = bool
  default     = false
}

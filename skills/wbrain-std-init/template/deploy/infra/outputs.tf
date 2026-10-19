output "instance_id" {
  value = aws_instance.this.id
}

output "elastic_ip" {
  value = aws_eip.this.public_ip
}

output "security_group_id" {
  value = aws_security_group.this.id
}

output "data_volume_id" {
  value = aws_ebs_volume.data.id
}

output "secret_name" {
  value = aws_secretsmanager_secret.env.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.env.arn
}

output "aws_region" {
  value = var.aws_region
}

output "ssm_log_group" {
  value = aws_cloudwatch_log_group.ssm.name
}

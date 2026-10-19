terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Parâmetros (bucket/key/region) vêm de deploy/config/config.yaml via `init -backend-config`.
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    # Project/Environment/Suffix: chaves para filtrar relatórios de custo (ativar como cost allocation tags).
    tags = merge(
      { Project = var.name, Environment = var.environment, ManagedBy = "terraform" },
      var.suffix != "" ? { Suffix = var.suffix } : {},
      var.tags,
    )
  }
}

terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Platform-Team"
  }
}

# Instantiate Networking module
module "vpc" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

  # Enable NAT Gateway to pull ECR images in private subnets
  # Use single NAT Gateway in dev to reduce costs
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = locals.tags
}

# Instantiate ECS Fargate Service module
module "ecs_service" {
  source = "../../modules/ecs-fargate-service"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  container_image = var.container_image
  container_port  = var.container_port

  desired_count         = 2
  cpu                   = "256"
  memory                = "512"
  log_retention_in_days = 30

  # Standard environment variables
  app_variables = {
    "NODE_ENV" = "production"
    "PORT"     = tostring(var.container_port)
  }

  # Example dynamic secrets/parameters mapping (referencing AWS resources)
  # In production, these would be direct ARNs to Secrets Manager or Parameter Store
  app_secrets = {
    "DB_PASSWORD_ARN" = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db_password-abcd12"
  }

  enable_autoscaling = true
  min_capacity       = 1
  max_capacity       = 3

  tags = locals.tags
}

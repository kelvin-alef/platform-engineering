variable "project_name" {
  type        = string
  description = "Project name to prefix resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ECS service and SG will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs (typically private subnets) for Fargate task placement"
}

variable "container_image" {
  type        = string
  description = "Docker image for the application container"
  default     = "nginx:latest"
}

variable "container_port" {
  type        = number
  description = "Port exposed by the application container"
  default     = 8080
}

variable "desired_count" {
  type        = number
  description = "Desired number of running task instances"
  default     = 2
}

variable "cpu" {
  type        = string
  description = "CPU units for the task definition (e.g. '256', '512', '1024')"
  default     = "256"

  validation {
    condition     = contains(["256", "512", "1024", "2048", "4096"], var.cpu)
    message       = "Fargate CPU must be one of: '256', '512', '1024', '2048', '4096'."
  }
}

variable "memory" {
  type        = string
  description = "Memory limit for the task definition in MB (e.g. '512', '1024', '2048')"
  default     = "512"

  validation {
    condition     = can(regex("^[0-9]+$", var.memory))
    message       = "Fargate memory must be a numeric string representing MB (e.g. '512')."
  }
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention period for CloudWatch logs in days"
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 730, 1827, 3653, 0], var.log_retention_in_days)
    message       = "CloudWatch Log retention must be a valid AWS retention period (e.g., 7, 14, 30, 90, 365) or 0 for infinite."
  }
}

variable "alb_target_group_arn" {
  type        = string
  description = "Optional ALB target group ARN to register Fargate tasks to a load balancer"
  default     = ""
}

variable "enable_autoscaling" {
  type        = bool
  description = "Toggle horizontal Pod/Task autoscaling"
  default     = false
}

variable "min_capacity" {
  type        = number
  description = "Minimum instances for autoscaling"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum instances for autoscaling"
  default     = 5
}

variable "cpu_threshold" {
  type        = number
  description = "Average CPU threshold in % to trigger autoscaling"
  default     = 70
}

variable "memory_threshold" {
  type        = number
  description = "Average Memory threshold in % to trigger autoscaling"
  default     = 70
}

variable "app_variables" {
  type        = map(string)
  description = "Non-sensitive application environment variables"
  default     = {}
}

variable "app_secrets" {
  type        = map(string)
  description = "AWS Secrets Manager ARNs or SSM Parameter Store ARNs for injecting sensitive environment variables"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to resources"
  default     = {}
}

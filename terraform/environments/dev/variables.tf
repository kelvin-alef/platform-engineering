variable "aws_region" {
  type        = string
  description = "AWS target region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "sample-app"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "container_image" {
  type        = string
  description = "Container image to deploy"
  default     = "sample-app:latest"
}

variable "container_port" {
  type        = number
  description = "Application port"
  default     = 8080
}

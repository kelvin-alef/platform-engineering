variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "sample-app"
}

variable "environment" {
  default = "dev"
}

variable "container_image" {
  default = "nginx:latest"
}

variable "container_port" {
  default = 80
}
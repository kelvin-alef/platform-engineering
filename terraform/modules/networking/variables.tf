variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. dev, staging, prod)"
}

variable "project_name" {
  type        = string
  description = "Name of the project to prefix resources"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones to deploy subnets"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private subnets"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Toggle the creation of a NAT Gateway (needed for private subnet internet egress)"
  default     = true
}

variable "single_nat_gateway" {
  type        = bool
  description = "Toggle to provision a single NAT Gateway across all zones to reduce cost in dev/staging"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to resources"
  default     = {}
}

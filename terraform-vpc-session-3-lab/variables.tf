variable "aws_region" {
  description = "AWS Region where the practice VPC will be created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name used to identify and tag the lab resources."
  type        = string
  default     = "terraform-session-3-lab"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}
variable "public_subnet_cidr" {
  description = "IPv4 CIDR block for the public subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR block for the private subnet."
  type        = string
  default     = "10.20.2.0/24"
}

variable "environment" {
  description = "Environment tag applied to the VPC and subnets."
  type        = string
  default     = "practice"

  validation {
    condition     = contains(["practice", "development", "test"], var.environment)
    error_message = "environment must be practice, development, or test."
  }
}

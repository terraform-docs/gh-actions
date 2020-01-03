variable "vpc_id" {
  description = "The id of the vpc"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet ids to use"
  type        = list(string)
}

variable "instance_name" {
  description = "Instance name prefix"
  type        = string
  default     = "test-"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "extra_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "extra_environment" {
  description = "List of additional environment variables"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

output "vpc_id" {
  description = "The Id of the VPC"
  value       = var.vpc_id
}

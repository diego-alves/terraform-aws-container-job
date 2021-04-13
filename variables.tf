# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# These variables must be set in the module block when using this module.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "ECS Service Name"
  type        = string
}

variable "cluster_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "cron" {
  description = "Cron: min hour day month day wday"
  type        = string
}

variable "subnets" {
  description = "Subnet list where the task will run"
  type        = list(string)
}

# variable "vpc_id" {
#   description = "VPC ID"
#   type        = string
# }

# variable "subnets" {
#   description = "List of Subnets to include in the ECS Service"
#   type        = set(string)
# }

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These variables have default values and don't have to be set to use this module.
# You may set these variables to override their default values.
# ---------------------------------------------------------------------------------------------------------------------

variable "image_tag" {
  description = "Docker Image tag"
  type        = string
  default     = "latest"
}

#  CPU  Memory
#  256  512, 1024, 2048
#  512  1024-4096
# 1024  2048-8192
# 2048  4096-16384
# 4096  8192-30720
variable "cpu" {
  description = "Then number of cpu units used by the task. (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 256
}

variable "mem" {
  description = "The amount (in MiB) of memory used by the task. (512, 1024, 2048, 4096, ...)"
  type        = number
  default     = 512
}

variable "environment" {
  description = "Environment Variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from Systems Manager Parameter Storage"
  type        = map(string)
  default     = {}
}

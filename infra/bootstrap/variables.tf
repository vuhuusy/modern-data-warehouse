################################################################################
# Bootstrap Variables
################################################################################

variable "aws_region" {
  description = "AWS region for the backend resources."
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project identifier used for naming resources."
  type        = string
  default     = "mdw"
}

variable "environments" {
  description = "List of environments to create backend resources for."
  type        = list(string)
  default     = ["dev"]
}

variable "owner" {
  description = "Owner tag for resources."
  type        = string
  default     = "syvh"
}

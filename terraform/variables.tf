variable "project_name" {
  description = "Name prefix for all AWS resources"
  type        = string
  default     = "devops-challenge"
}

variable "aws_region" {
  description = "AWS region where all resources will be deployed"
  type        = string
  default     = "eu-west-3"
}

variable "approval_email" {
  description = "Email address for SNS approval notifications. Leave empty to skip email (approve via AWS Console or CLI instead)."
  type        = string
  default     = ""
}

variable "codecommit_repo_name" {
  description = "Name of the CodeCommit repository that triggers the pipeline"
  type        = string
  default     = "springboot-app"
}

variable "branch_name" {
  description = "Git branch that triggers the pipeline"
  type        = string
  default     = "main"
}

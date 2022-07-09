variable "ecr_repo" {
  type        = string
  description = "Name of the ECR repository."
}

variable "ci_name" {
  type        = string
  description = "Name of the CI system (e.g., CircleCI, Github, …)."
}

variable "ci_project" {
  type        = string
  description = "Name of the project being built. Uses ecr_repo name by default."
  default     = ""
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to be applied to CI user"
  default     = {}
}

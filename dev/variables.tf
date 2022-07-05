variable "name_prefix" {
  type        = string
  description = "Name prefix to be used in names and tags for all resources that are being created"
}

variable "region" {
  type        = string
  description = "Region to spin up EKS cluster and corresponding resources in"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC to be used for EKS"
}

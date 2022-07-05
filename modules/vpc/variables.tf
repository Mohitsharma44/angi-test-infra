variable "name_prefix" {
  type = string
  description = "Name to be used as a prefix for VPC resources"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR block for VPC"
}

variable "total_subnets" {
  type = number
  description = "Total number of subnets required. Must be power of 2. e.g. 8, 16, 32, 64..."
  default = 16
}

variable "common_vpc_tags" {
  type = map(string)
  description = "Additional tags to be applied to the VPC and all private and public subnets in VPC"
}

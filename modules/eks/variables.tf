variable "cluster_name" {
  type = string
  description = "Name of the EKS cluster"
}

variable "additional_iam_policies_for_nodegroups" {
  type = list
  description = "Additional IAM policies to be applied to nodegroups"
  default = []
}

variable "region" {
  type = string
  description = "Region to spin up EKS cluster in"
  default = "us-west-2"
}

variable "kubernetes_version" {
  type = string
  description = "EKS Kubernetes version to use"
  default = "1.22"
}

variable "vpc_id" {
  type = string
  description = "VPC Id for the VPC created for EKS cluster"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "Ids of private subnets to be used with fargate"
}

variable "eks_tags" {
  type = map(string)
  description = "Tags to be applied to the EKS cluster"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "additional_iam_policies_for_nodegroups" {
  type        = list(any)
  description = "Additional IAM policies to be applied to nodegroups"
  default     = []
}

variable "region" {
  type        = string
  description = "Region to spin up EKS cluster in"
  default     = "us-west-2"
}

variable "kubernetes_version" {
  type        = string
  description = "EKS Kubernetes version to use"
  default     = "1.22"
}

variable "vpc_id" {
  type        = string
  description = "VPC Id for the VPC created for EKS cluster"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Ids of private subnets to be used with fargate"
}

variable "eks_tags" {
  type        = map(string)
  description = "Tags to be applied to the EKS cluster"
}

variable "list_of_maps_of_authenticated_users" {
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  description = <<-EOT
  List of map of users that are allowed to access the cluster. E.g.
  [
    {
      userarn  = "arn:aws:iam::<aws-account-id>:user/<username>"         # The ARN of the IAM user to add.
      username = "<username>"                                            # The user name within Kubernetes to map to the IAM user
      groups   = ["system:masters"]                                      # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ]
  EOT
  default     = []
}

variable "list_of_maps_of_authenticated_roles" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = <<-EOT
  List of map of users that are allowed to access the cluster. E.g.
  [
    {
      rolearn  = "arn:aws:iam::<aws-account-id>:role/<role_name>"         # The ARN of the IAM role
      username = "<username>"                                            # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                      # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ]
  EOT
  default     = []
}

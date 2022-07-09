locals {
  additional_iam_policies_for_nodegroups = length(var.additional_iam_policies_for_nodegroups) > 0 ? var.additional_iam_policies_for_nodegroups : []
  map_users                              = length(var.list_of_maps_of_authenticated_users) > 0 ? var.list_of_maps_of_authenticated_users : []
  map_roles                              = length(var.list_of_maps_of_authenticated_roles) > 0 ? var.list_of_maps_of_authenticated_roles : []
}

data "aws_caller_identity" "current" {}

module "eks_blueprints" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=v4.3.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  cluster_kms_key_additional_admin_arns = [data.aws_caller_identity.current.arn]

  map_users = local.map_users
  map_roles = local.map_roles

  node_security_group_additional_rules = {
    # Extend node-to-node security group rules. Recommended and required for the Add-ons
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # Recommended outbound traffic for Node groups
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    # Allows Control Plane Nodes to talk to Worker nodes on all ports. Added this to simplify the example and further avoid issues with Add-ons communication with Control plane.
    # This can be restricted further to specific port based on the requirement for each Add-on e.g., metrics-server 4443, spark-operator 8080, karpenter 8443 etc.
    # Change this according to your security requirements if needed
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  managed_node_groups = {
    spot_2vcpu_8mem = {
      node_group_name   = "managed-spot-2vcpu-8mem"
      capacity_type     = "SPOT"
      instance_types    = ["m5.large", "m4.large", "m6a.large", "m5a.large", "m5d.large"]
      enable_monitoring = true
      eni_delete        = true

      subnet_type = "private"
      subnet_ids  = var.private_subnet_ids

      desired_size = 3
      max_size     = 10
      min_size     = 2

      disk_size = 100
      update_config = [{
        max_unavailable_percentage = 30
      }]

      additional_iam_policies = local.additional_iam_policies_for_nodegroups

      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/eks.amazonaws.com/capacityType" = "SPOT"
        "k8s.io/cluster-autoscaler/node-template/label/eks/node_group_name"            = "spot-2vcpu-8mem"
      }
    }
    spot_4vcpu_16mem = {
      node_group_name   = "managed-spot-4vcpu-16mem"
      capacity_type     = "SPOT"
      instance_types    = ["m5.xlarge", "m4.xlarge", "m6a.xlarge", "m5a.xlarge", "m5d.xlarge"]
      enable_monitoring = true
      eni_delete        = true

      subnet_type = "private"
      subnet_ids  = var.private_subnet_ids

      desired_size = 3
      max_size     = 10
      min_size     = 2

      disk_size = 100
      update_config = [{
        max_unavailable_percentage = 30
      }]

      additional_iam_policies = local.additional_iam_policies_for_nodegroups

      additional_tags = {
        "k8s.io/cluster-autoscaler/node-template/label/eks.amazonaws.com/capacityType" = "SPOT"
        "k8s.io/cluster-autoscaler/node-template/label/eks/node_group_name"            = "spot-4vcpu-16mem"
      }
    }
  }

  tags = var.eks_tags
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.3.0"

  eks_cluster_id       = module.eks_blueprints.eks_cluster_id
  eks_cluster_endpoint = module.eks_blueprints.eks_cluster_endpoint
  eks_oidc_provider    = module.eks_blueprints.oidc_provider
  eks_cluster_version  = module.eks_blueprints.eks_cluster_version

  enable_cluster_autoscaler = true
  cluster_autoscaler_helm_config = {
    set = [
      {
        name  = "extraArgs.expander"
        value = "priority"
      },
      {
        name  = "expanderPriorities"
        value = <<-EOT
                  90:
                    - spot-2vcpu-8mem.*
                  50:
                    - spot-4vcpu-16mem.*
                  10:
                    - .*
                EOT
      }
    ]
  }
}

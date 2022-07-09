data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalTag/eks_cluster"
      values   = ["${var.name_prefix}-eks"]
    }
  }
}

data "aws_iam_policy_document" "allow_tf_plans" {
  # Special statement to allow github user be able to run terraform plans
  # generated using iamlive and running terraform plan
  statement {
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcClassicLink",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcs",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:ListTagsForResource",
      "eks:DescribeAddon",
      "eks:DescribeAddonVersions",
      "eks:DescribeCluster",
      "eks:DescribeNodegroup",
      "eks:ListClusters",
      "iam:GetGroup",
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetUser",
      "iam:ListAttachedGroupPolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListResourceTags",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "allow_tf_plans" {
  name   = "allow_tf_plans"
  policy = data.aws_iam_policy_document.allow_tf_plans.json

}

resource "aws_iam_role" "to_access_eks_cluster" {
  name               = "access_${var.name_prefix}-eks_cluster"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "allow_tf_plans" {
  role       = aws_iam_role.to_access_eks_cluster.name
  policy_arn = aws_iam_policy.allow_tf_plans.arn
}

locals {
  common_tags = {
    "eks_cluster" = "${var.name_prefix}-eks"
    "candidate"   = "Mohit"
    "region"      = var.region
  }
}

module "network" {
  source = "../modules/vpc"

  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr

  common_vpc_tags = local.common_tags
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "v1.3.2"

  repository_name = "${var.name_prefix}-repo"
  repository_type = "private"

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 10 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "eks_cluster_node_inline_addon_policy" {
  name        = "${var.name_prefix}-eks-cluster-node-inline-addon-policy"
  path        = "/"
  description = "EKS Node Access to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "${module.ecr.repository_arn}/*"
      },
    ]
  })
}

module "ci_user" {
  source = "../modules/ci-user"

  ecr_repo    = "${var.name_prefix}-repo"
  ci_name     = "githubUser"
  ci_project  = "angitest"
  common_tags = local.common_tags
}

module "eks_cluster" {
  source = "../modules/eks"

  cluster_name                           = "${var.name_prefix}-eks"
  vpc_id                                 = module.network.vpc_id
  private_subnet_ids                     = module.network.private_subnet_ids
  additional_iam_policies_for_nodegroups = [aws_iam_policy.eks_cluster_node_inline_addon_policy.arn]
  eks_tags                               = local.common_tags
  # list_of_maps_of_authenticated_users = [
  #   {
  #     userarn : module.ci_user.user_arn,
  #     username : module.ci_user.user_name,
  #     groups : ["system:masters"]
  #   }
  # ]
  list_of_maps_of_authenticated_roles = [
    {
      rolearn : aws_iam_role.to_access_eks_cluster.arn
      username : aws_iam_role.to_access_eks_cluster.name
      groups : ["system:masters"]
    }
  ]
}

module "dev_eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.3.0"

  eks_cluster_id       = module.eks_cluster.cluster_id
  eks_cluster_endpoint = module.eks_cluster.cluster_endpoint
  eks_oidc_provider    = module.eks_cluster.oidc_provider
  eks_cluster_version  = module.eks_cluster.kubernetes_version

  enable_argocd = true
  # argocd_manage_add_ons = true
  argocd_applications = {
    demo = {
      path               = "argo_applications/envs/dev"
      repo_url           = "https://github.com/Mohitsharma44/angi-test-charts.git"
      add_on_application = false
    }
  }

  enable_cert_manager   = true
  enable_metrics_server = true
  enable_prometheus     = true

  enable_amazon_eks_coredns = true
  enable_amazon_eks_vpc_cni = true
  amazon_eks_vpc_cni_config = {
    addon_version     = data.aws_eks_addon_version.this["vpc-cni"].version
    resolve_conflicts = "OVERWRITE"
  }

  enable_amazon_eks_kube_proxy = true
  amazon_eks_kube_proxy_config = {
    addon_version     = data.aws_eks_addon_version.this["kube-proxy"].version
    resolve_conflicts = "OVERWRITE"
  }

  enable_ingress_nginx = true
  ingress_nginx_helm_config = {
    version          = "4.0.17"
    create_namespace = true
    values           = [templatefile("${path.module}/templates/nginx_values.yaml", {})]
  }

  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_helm_config = {
    values = [
      <<-EOT
      clusterName: ${module.eks_cluster.cluster_id}
      region: ${var.region}
      vpcId: ${module.network.vpc_id}
      EOT
    ]
  }

  tags = local.common_tags
}

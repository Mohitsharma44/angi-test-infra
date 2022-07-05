locals {
  project = var.ci_project == "" ? var.ecr_repo : var.ci_project
}

data "aws_ecr_repository" "main" {
  name = var.ecr_repo
}

resource "aws_iam_user" "ci" {
  name          = "${lower(var.ci_name)}-${local.project}"
  force_destroy = true

  tags = var.common_tags
}

resource "aws_iam_group" "cigroup" {
  name = "${lower(var.ci_name)}-${local.project}"
}

resource "aws_iam_group_membership" "main" {
  name  = "${lower(var.ci_name)}-${local.project}-group-membership"
  users = [aws_iam_user.ci.name]
  group = aws_iam_group.cigroup.name
}

data "aws_iam_policy_document" "allow_ecr_push" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]

    resources = [
      data.aws_ecr_repository.main.arn,
    ]
  }

  # Special statement to allow github user be able to run terraform plans
  # generated using iamlive and running terraform plan
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAvailabilityZones",
      "ecr:DescribeRepositories",
      "ec2:DescribeVpcs",
      "ecr:ListTagsForResource",
      "ec2:DescribeVpcClassicLink",
      "ecr:GetLifecyclePolicy",
      "ec2:DescribeVpcClassicLinkDnsSupport",
      "ec2:DescribeVpcAttribute",
      "iam:GetGroup",
      "iam:GetUser",
      "ec2:DescribeNetworkAcls",
      "ecr:GetRepositoryPolicy",
      "ec2:DescribeAddresses",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "iam:GetPolicy",
      "kms:DescribeKey",
      "iam:GetRole",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "iam:GetPolicyVersion",
      "ec2:DescribeSubnets",
      "kms:ListResourceTags",
      "ec2:DescribeInternetGateways",
      "kms:ListAliases",
      "iam:ListAttachedGroupPolicies",
      "ec2:DescribeNatGateways",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "eks:DescribeCluster",
      "ec2:DescribeTags",
      "eks:DescribeAddonVersions",
      "iam:GetOpenIDConnectProvider",
      "eks:DescribeAddon",
      "iam:GetInstanceProfile",
      "eks:DescribeNodegroup"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "allow_ecr_push" {
  name        = "${lower(var.ci_name)}-ecr-${var.ecr_repo}-policy"
  description = "Allow ${var.ci_name} to push new ${var.ecr_repo} ECR images"
  path        = "/"
  policy      = data.aws_iam_policy_document.allow_ecr_push.json
}

resource "aws_iam_group_policy_attachment" "main" {
  group      = aws_iam_group.cigroup.name
  policy_arn = aws_iam_policy.allow_ecr_push.arn
}

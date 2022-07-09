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

data "aws_iam_policy_document" "for_ci_user" {
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

  statement {
    actions   = ["sts:AssumeRole"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "for_ci_user" {
  name        = "${lower(var.ci_name)}-ecr-${var.ecr_repo}-policy"
  description = "Allow ${var.ci_name} to push new ${var.ecr_repo} ECR images"
  path        = "/"
  policy      = data.aws_iam_policy_document.for_ci_user.json
}

resource "aws_iam_group_policy_attachment" "main" {
  group      = aws_iam_group.cigroup.name
  policy_arn = aws_iam_policy.for_ci_user.arn
}

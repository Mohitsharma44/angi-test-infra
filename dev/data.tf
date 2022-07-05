data "aws_eks_addon_version" "this" {
  for_each = toset(["coredns", "kube-proxy", "vpc-cni"])

  addon_name         = each.value
  kubernetes_version = module.eks_cluster.kubernetes_version
  most_recent        = true
}

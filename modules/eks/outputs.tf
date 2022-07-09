output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks_blueprints.eks_cluster_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks_blueprints.eks_cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks_blueprints.eks_cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = module.eks_blueprints.configure_kubectl
}

output "kubernetes_version" {
  description = "Kubernetes version running in cluster"
  value       = module.eks_blueprints.eks_cluster_version
}

output "oidc_provider" {
  description = "OIDC provider for the EKS cluster"
  value       = module.eks_blueprints.oidc_provider
}

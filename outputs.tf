output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
  # This is the API server endpoint for your Kubernetes cluster
  # You'll use this with kubectl to interact with your cluster
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
  # Useful for referencing your cluster in AWS console and CLI commands
}

output "region" {
  description = "AWS region"
  value       = var.region
  # Region where the cluster is deployed
  # Useful for AWS CLI commands
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
  # This command configures your local kubectl to connect to your EKS cluster
  # Run this after terraform apply completes to set up your connection
}
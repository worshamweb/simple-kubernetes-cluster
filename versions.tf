terraform {
  required_version = ">= 1.5.0"
  # Using recent Terraform version for better AWS provider compatibility
  # and access to newer language features

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      # Using latest major version of AWS provider for access to all current features
      # Tilde (~>) ensures we get patch and minor updates but not major version changes
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
      # Adding Kubernetes provider for deploying resources to our EKS cluster
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
      # Adding Helm provider for deploying ArgoCD
    }
  }
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
  # us-east-1 often has the most services available and is a common default choice
  # For production, consider choosing a region closer to your users for lower latency
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "simple-eks-cluster"
  # Naming convention follows k8s standard of lowercase with hyphens
  # In production, consider adding environment or team prefixes (e.g., prod-team-eks-cluster)
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
  # Using the latest stable version as of creation time
  # For production, consider n-1 version for stability while still receiving security updates
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  # Standard private IP range with plenty of addresses
  # For production, coordinate with network team to avoid overlaps with existing networks
}

variable "instance_type" {
  description = "EC2 instance type for the EKS node group"
  type        = string
  default     = "t3a.small"
  # t3a.small is cost-effective for prototype/learning (2 vCPU, 2GB RAM)
  # Uses AMD processors which are ~10% cheaper than Intel equivalents
  # For production, consider:
  # - t3a.medium or larger for general workloads (4GB RAM)
  # - c5a.large for compute-intensive workloads
  # - m5a.large for memory-intensive workloads
  # Note: t3a.micro is in free tier but too small for Kubernetes (only 1GB RAM)
}
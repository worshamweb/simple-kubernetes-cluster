# Configure the Helm provider to use our EKS cluster
# This provider will use the same authentication as the Kubernetes provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Create a namespace for ArgoCD
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  
  depends_on = [module.eks]
}

# Deploy ArgoCD using the Helm chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7"  # Specify a version for reproducibility
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  
  # Basic configuration values for ArgoCD
  set {
    name  = "server.service.type"
    value = "ClusterIP"  # Using ClusterIP for prototype simplicity
  }
  
  set {
    name  = "controller.resources.limits.cpu"
    value = "500m"  # Limiting CPU usage for cost efficiency
  }
  
  set {
    name  = "controller.resources.limits.memory"
    value = "512Mi"  # Limiting memory usage for cost efficiency
  }
  
  set {
    name  = "server.resources.limits.cpu"
    value = "500m"
  }
  
  set {
    name  = "server.resources.limits.memory"
    value = "512Mi"
  }
  
  # Only deploy ArgoCD after the namespace is created
  depends_on = [kubernetes_namespace.argocd]
}
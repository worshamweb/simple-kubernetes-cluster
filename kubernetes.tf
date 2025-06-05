# Configure the Kubernetes provider to use our EKS cluster
# This provider will use the kubeconfig that's generated after EKS cluster creation
# Note: You must run 'terraform apply' twice:
# - First to create the EKS cluster
# - Second to create these Kubernetes resources after the cluster is ready
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Create a namespace for our application
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
  }
  
  # Only create this after the EKS cluster is fully provisioned
  depends_on = [module.eks]
}

# Create a ClusterIP service to expose the NGINX deployment
resource "kubernetes_service" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  
  spec {
    selector = {
      app = kubernetes_deployment.nginx.metadata[0].labels.app
    }
    
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    
    type = "ClusterIP"
  }
  
  # Only create this after the deployment is created
  depends_on = [kubernetes_deployment.nginx]
}
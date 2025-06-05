# Create a ConfigMap to store application configuration
# ConfigMaps are used to store non-confidential data in key-value pairs
resource "kubernetes_config_map" "nginx_config" {
  metadata {
    name      = "nginx-config"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }

  # Configuration data for NGINX
  data = {
    "nginx.conf" = <<-EOT
      server {
        listen 80;
        server_name localhost;
        
        location / {
          root /usr/share/nginx/html;
          index index.html index.htm;
          # Custom configuration from ConfigMap
          add_header X-Config-Source "Terraform ConfigMap";
        }
      }
    EOT
    
    "default.conf" = "server_tokens off;"
    "environment"  = "development"
  }

  depends_on = [kubernetes_namespace.dev]
}

# Create a Secret to store sensitive information
# Secrets are similar to ConfigMaps but are intended for confidential data
resource "kubernetes_secret" "nginx_secret" {
  metadata {
    name      = "nginx-secret"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }

  # Secret data - in a real environment, avoid storing actual secrets in your Terraform code
  # These values are base64 encoded automatically by Kubernetes
  data = {
    "api-key"     = "demo-api-key-for-prototype"
    "db-password" = "demo-password-for-prototype"
  }

  # Type of secret - Opaque is the default generic type
  type = "Opaque"

  depends_on = [kubernetes_namespace.dev]
}

# Update the NGINX deployment to use the ConfigMap and Secret
resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.dev.metadata[0].name
    
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          
          port {
            container_port = 80
          }
          
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "0.2"
              memory = "256Mi"
            }
          }
          
          # Mount the ConfigMap as a volume
          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }
          
          # Use Secret as environment variables
          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.nginx_secret.metadata[0].name
                key  = "api-key"
              }
            }
          }
          
          env {
            name = "ENV_TYPE"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.nginx_config.metadata[0].name
                key  = "environment"
              }
            }
          }
        }
        
        # Define the volume from ConfigMap
        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map.nginx_config.metadata[0].name
            items {
              key  = "nginx.conf"
              path = "custom-nginx.conf"
            }
          }
        }
      }
    }
  }
  
  depends_on = [
    kubernetes_namespace.dev,
    kubernetes_config_map.nginx_config,
    kubernetes_secret.nginx_secret
  ]
}
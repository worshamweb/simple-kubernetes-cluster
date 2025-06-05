# Simple Kubernetes Cluster on AWS EKS

This Terraform project creates a minimal Kubernetes cluster on AWS using EKS (Elastic Kubernetes Service) for learning and prototyping purposes.

## Architecture

- VPC with two public subnets in different availability zones (EKS requirement)
- EKS cluster with one node group
- NGINX deployment in a "dev" namespace with a ClusterIP service
- ConfigMap and Secret for configuration management
- ArgoCD deployment using Helm for GitOps capabilities

## Cost Considerations

This prototype has been optimized for learning while minimizing costs:

- **EKS Control Plane**: ~$0.10/hour ($73/month) - Not covered by free tier
- **Worker Node**: t3a.small instance ~$0.019/hour ($13.87/month)
- **VPC Components**: No direct cost
- **Total Estimated Cost**: ~$0.12/hour or ~$2.88/day

To minimize costs:
- Destroy the cluster when not in use
- The smallest viable instance type (t3a.small) is used for worker nodes
- Single node configuration to reduce compute costs
- Resource limits set on all deployments

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- kubectl for interacting with the cluster

### Installing kubectl on Ubuntu

If you're using Ubuntu, install kubectl with:
```
sudo snap install kubectl --classic
```

The `--classic` flag is required because kubectl needs additional system permissions.

## Usage

### 1. Deploy the EKS Cluster

Initialize Terraform:
```
terraform init
```

Apply the configuration to create the EKS infrastructure:
```
terraform apply
```

### 2. Configure kubectl

After the cluster is created, configure kubectl to connect to your cluster:
```
aws eks update-kubeconfig --region $(terraform output -raw region) --name $(terraform output -raw cluster_name)
```

### 3. Verify the Cluster

Check that your node is running:
```
kubectl get nodes
```

### 4. Deploy the Kubernetes Resources

Apply the Terraform configuration again to create the Kubernetes resources:
```
terraform apply
```

Verify the resources were created:
```
kubectl get namespaces
kubectl get deployments -n dev
kubectl get svc -n dev
kubectl get configmaps -n dev
kubectl get secrets -n dev
kubectl get pods -n argocd
```

### 5. Access the NGINX Application

The NGINX deployment is exposed via a ClusterIP service within the cluster. To access it:

1. Get the service IP:
   ```
   kubectl get svc -n dev nginx
   ```

2. Create a port-forward to access it from your local machine:
   ```
   kubectl port-forward -n dev svc/nginx 8080:80
   ```

3. Open a browser and navigate to http://localhost:8080

### 6. Access ArgoCD

ArgoCD is deployed with a ClusterIP service. To access the ArgoCD UI:

1. Create a port-forward:
   ```
   kubectl port-forward -n argocd svc/argocd-server 8080:443
   ```

2. Get the initial admin password:
   ```
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. Open a browser and navigate to https://localhost:8080
   - Username: admin
   - Password: (from the command above)

## Key Components Explained

### ConfigMaps and Secrets

**ConfigMaps** are Kubernetes resources used to store non-confidential configuration data in key-value pairs. They allow you to:
- Decouple configuration from container images
- Store configuration files, command-line arguments, environment variables
- Update configuration without rebuilding container images

In this prototype, we use a ConfigMap to store NGINX configuration settings.

**Secrets** are similar to ConfigMaps but are specifically designed for storing sensitive information like:
- API keys
- Passwords
- TLS certificates
- OAuth tokens

In this prototype, we use a Secret to store a demo API key and database password. The Secret is mounted as environment variables in the NGINX container.

### Helm and ArgoCD

**Helm** is a package manager for Kubernetes that allows you to:
- Define, install, and upgrade complex Kubernetes applications
- Use pre-packaged "charts" (bundles of Kubernetes resources)
- Manage releases and rollbacks
- Parameterize deployments with values

In this prototype, we use the Helm provider in Terraform to deploy ArgoCD from its official chart.

**ArgoCD** is a GitOps continuous delivery tool for Kubernetes that:
- Automates the deployment of applications from Git repositories
- Ensures the deployed state matches the desired state in Git
- Provides a web UI for visualizing application deployments
- Supports multiple environments and promotion workflows

In this prototype, ArgoCD is deployed as a basic installation that you can use to explore GitOps principles.

## Learning Notes

This project demonstrates:
- Basic Terraform structure and AWS resource creation
- EKS cluster configuration with managed node groups
- Networking setup for Kubernetes on AWS
- Using the Kubernetes provider in Terraform to deploy applications
- Configuration management with ConfigMaps and Secrets
- Package management with Helm
- GitOps principles with ArgoCD
- Infrastructure as Code best practices

## EKS Requirements

Note that EKS has certain requirements that cannot be bypassed:
- Subnets must be in at least two different Availability Zones
- Control plane needs multi-AZ for high availability
- Worker nodes can be in a single AZ to minimize costs

## Clean Up

To destroy all resources and stop incurring costs:
```
terraform destroy
```

This single command will completely remove all resources created by this project:
1. All Kubernetes resources (NGINX, ConfigMaps, Secrets, ArgoCD)
2. The EKS cluster and its control plane
3. The node group and its EC2 instances
4. All networking components (VPC, subnets, internet gateway)
5. All IAM roles and security groups

The process takes approximately 10-15 minutes to complete.

**Note**: If you've made changes to the configuration (like adding providers), you might need to run `terraform init -upgrade` before destroying to update the dependency lock file.

**Important**: Remember to run `terraform destroy` when you're done with the prototype to avoid unnecessary charges.

## Troubleshooting

### Dependency Lock File Issues

If you see an error like:
```
Error: Inconsistent dependency lock file
```

Run the following command to update the lock file:
```
terraform init -upgrade
```

This is needed when you add or update providers in your configuration.
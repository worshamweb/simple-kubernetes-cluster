provider "aws" {
  region = var.region
  # Region is parameterized to allow easy deployment to different regions
}

# Get availability zones
data "aws_availability_zones" "available" {}
# Using data source instead of hardcoding AZs improves portability across regions

# Create VPC with public subnets
resource "aws_vpc" "eks_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  # DNS support is required for EKS to function properly

  tags = {
    Name = "${var.cluster_name}-vpc"
    # Consistent naming convention using cluster name as prefix
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.eks_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
  # Internet Gateway is required for public subnet connectivity
  # Note: This is a managed service with no direct costs
}

# Create public subnets in two AZs
resource "aws_subnet" "public" {
  count = 2  # Creating 2 subnets to satisfy EKS requirement for multiple AZs
  
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                      = "${var.cluster_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
}

# Create route table - REQUIRED DEVIATION FROM INSTRUCTIONS
# Note: While the instructions specified "no route tables", AWS requires a route table
# for any subnet to have internet connectivity. Without this, the EKS nodes would have
# no way to communicate with the internet or the EKS control plane.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# Associate route table with subnets - REQUIRED DEVIATION FROM INSTRUCTIONS
# This is necessary for the subnets to use the route table defined above
resource "aws_route_table_association" "public" {
  count = 2
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = aws_vpc.eks_vpc.id
  # REQUIRED DEVIATION FROM INSTRUCTIONS: EKS requires subnets in at least 2 different AZs
  # AWS enforces this requirement and will not allow cluster creation with a single subnet
  subnet_ids = aws_subnet.public[*].id

  cluster_endpoint_public_access = true

  # Basic node group with default settings as requested
  eks_managed_node_groups = {
    default = {
      name         = "default-node-group"
      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = [var.instance_type]
      capacity_type  = "ON_DEMAND"

      # Using only one subnet for the node group to minimize costs
      # While control plane needs multiple AZs, worker nodes can be in one
      subnet_ids = [aws_subnet.public[0].id]
    }
  }

  # Allow nodes to be placed in public subnet
  node_security_group_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}
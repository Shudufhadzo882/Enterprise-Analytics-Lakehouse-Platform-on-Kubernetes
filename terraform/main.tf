# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    spark_workloads = {
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      instance_types = ["m5.xlarge", "m5.2xlarge"]
      capacity_type  = "SPOT"

      labels = {
        role = "spark-worker"
      }
    }

    core_apps = {
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      instance_types = ["m5.large"]
      capacity_type  = "ON_DEMAND"

      labels = {
        role = "core-services"
      }
    }
  }
}

# S3 Buckets for Medallion Architecture (Bronze, Silver, Gold)
resource "aws_s3_bucket" "bronze" {
  bucket        = "${var.s3_bucket_prefix}-bronze-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket" "silver" {
  bucket        = "${var.s3_bucket_prefix}-silver-${var.environment}"
  force_destroy = true
}

resource "aws_s3_bucket" "gold" {
  bucket        = "${var.s3_bucket_prefix}-gold-${var.environment}"
  force_destroy = true
}

# Enable Server-Side Encryption for Lakehouse Buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "bronze_enc" {
  bucket = aws_s3_bucket.bronze.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "silver_enc" {
  bucket = aws_s3_bucket.silver.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gold_enc" {
  bucket = aws_s3_bucket.gold.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM IRSA Policy for S3 Lakehouse Access
resource "aws_iam_policy" "s3_lakehouse_access" {
  name        = "${var.cluster_name}-s3-access-policy"
  description = "Allows EKS pods (Spark/Airflow/dbt) to access Lakehouse S3 Buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.bronze.arn,
          "${aws_s3_bucket.bronze.arn}/*",
          aws_s3_bucket.silver.arn,
          "${aws_s3_bucket.silver.arn}/*",
          aws_s3_bucket.gold.arn,
          "${aws_s3_bucket.gold.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::nyc-tlc",
          "arn:aws:s3:::nyc-tlc/*"
        ]
      }
    ]
  })
}

# IRSA Role for Spark Service Account
module "spark_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-spark-sa-role"

  role_policy_arns = {
    s3_policy = aws_iam_policy.s3_lakehouse_access.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["default:spark-sa", "analytics:spark-sa"]
    }
  }
}

# IRSA Role for Airflow Service Account
module "airflow_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name = "${var.cluster_name}-airflow-sa-role"

  role_policy_arns = {
    s3_policy = aws_iam_policy.s3_lakehouse_access.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["airflow:airflow-sa"]
    }
  }
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster API Endpoint"
  value       = module.eks.cluster_endpoint
}

output "s3_bronze_bucket" {
  description = "Bronze Medallion S3 Bucket Name"
  value       = aws_s3_bucket.bronze.id
}

output "s3_silver_bucket" {
  description = "Silver Medallion S3 Bucket Name"
  value       = aws_s3_bucket.silver.id
}

output "s3_gold_bucket" {
  description = "Gold Medallion S3 Bucket Name"
  value       = aws_s3_bucket.gold.id
}

output "spark_irsa_role_arn" {
  description = "IAM Role ARN for Spark Service Account"
  value       = module.spark_irsa.iam_role_arn
}

output "airflow_irsa_role_arn" {
  description = "IAM Role ARN for Airflow Service Account"
  value       = module.airflow_irsa.iam_role_arn
}

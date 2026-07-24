from pyspark.sql import SparkSession
import os

def create_spark_session(app_name: str = "EAL-K8s-PySpark-ETL") -> SparkSession:
    """
    Creates and configures a standardized PySpark session with S3A Hadoop driver
    support for anonymous S3 reads (NYC TLC dataset) and standard AWS S3 bucket operations.
    """
    builder = (
        SparkSession.builder
        .appName(app_name)
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
        .config("spark.sql.execution.arrow.pyspark.enabled", "true")
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("spark.hadoop.fs.s3a.aws.credentials.provider", 
                "com.amazonaws.auth.DefaultAWSCredentialsProviderChain,com.amazonaws.auth.AnonymousAWSCredentialsProvider")
    )

    # Optional local development overrides
    if os.getenv("SPARK_LOCAL_DEV", "false").lower() == "true":
        builder = builder.master("local[*]")

    spark = builder.getOrCreate()
    spark.sparkContext.setLogLevel("WARN")
    return spark

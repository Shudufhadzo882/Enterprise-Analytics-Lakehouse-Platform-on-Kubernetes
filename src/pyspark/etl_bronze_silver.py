#!/usr/bin/env python3
"""
PySpark ETL: Bronze & Silver Medallion Processing for NYC TLC Trip Data
Author: Enterprise Analytics Lakehouse Team
"""

import sys
import argparse
from pyspark.sql import functions as F
from pyspark.sql.types import DoubleType, IntegerType, TimestampType
from utils.spark_session import create_spark_session

def process_bronze_to_silver(input_path: str, bronze_output_path: str, silver_output_path: str):
    print(f"[*] Starting PySpark ETL Job...")
    print(f"[*] Input Path: {input_path}")
    print(f"[*] Bronze Output Path: {bronze_output_path}")
    print(f"[*] Silver Output Path: {silver_output_path}")

    spark = create_spark_session("EAL-K8s-Bronze-Silver-ETL")

    # ----------------------------------------------------
    # 1. BRONZE LAYER: Raw Data Ingestion & Metadata Tagging
    # ----------------------------------------------------
    print("\n[+] Ingesting Raw Data to Bronze Layer...")
    raw_df = spark.read.option("header", "true").parquet(input_path)

    bronze_df = raw_df \
        .withColumn("ingested_at", F.current_timestamp()) \
        .withColumn("source_path", F.input_file_name())

    print(f"[*] Writing to Bronze Parquet Destination: {bronze_output_path}")
    bronze_df.write.mode("overwrite").parquet(bronze_output_path)

    # ----------------------------------------------------
    # 2. SILVER LAYER: Data Cleaning, Schema Standardization & Feature Engineering
    # ----------------------------------------------------
    print("\n[+] Transforming Data to Silver Layer...")
    
    # Identify timestamp columns dynamically (Yellow vs Green vs FHV)
    pickup_col = "tpep_pickup_datetime" if "tpep_pickup_datetime" in bronze_df.columns else "lpep_pickup_datetime"
    dropoff_col = "tpep_dropoff_datetime" if "tpep_dropoff_datetime" in bronze_df.columns else "lpep_dropoff_datetime"

    silver_df = bronze_df \
        .withColumn("vendor_id", F.col("VendorID").cast(IntegerType())) \
        .withColumn("pickup_datetime", F.col(pickup_col).cast(TimestampType())) \
        .withColumn("dropoff_datetime", F.col(dropoff_col).cast(TimestampType())) \
        .withColumn("passenger_count", F.coalesce(F.col("passenger_count").cast(IntegerType()), F.lit(1))) \
        .withColumn("trip_distance", F.col("trip_distance").cast(DoubleType())) \
        .withColumn("rate_code_id", F.col("RatecodeID").cast(IntegerType())) \
        .withColumn("payment_type", F.col("payment_type").cast(IntegerType())) \
        .withColumn("fare_amount", F.col("fare_amount").cast(DoubleType())) \
        .withColumn("tip_amount", F.col("tip_amount").cast(DoubleType())) \
        .withColumn("tolls_amount", F.col("tolls_amount").cast(DoubleType())) \
        .withColumn("total_amount", F.col("total_amount").cast(DoubleType())) \
        .withColumn("pickup_location_id", F.col("PULocationID").cast(IntegerType())) \
        .withColumn("dropoff_location_id", F.col("DOLocationID").cast(IntegerType()))

    # Apply Quality Filters & Calculated Fields
    clean_silver_df = silver_df \
        .filter(F.col("pickup_datetime").isNotNull() & F.col("dropoff_datetime").isNotNull()) \
        .filter(F.col("trip_distance") > 0.0) \
        .filter(F.col("fare_amount") >= 0.0) \
        .filter(F.col("total_amount") >= 0.0) \
        .withColumn("trip_duration_seconds", 
                    (F.col("dropoff_datetime").cast("long") - F.col("pickup_datetime").cast("long"))) \
        .filter(F.col("trip_duration_seconds") > 0) \
        .withColumn("trip_duration_minutes", F.round(F.col("trip_duration_seconds") / 60.0, 2)) \
        .withColumn("tip_percentage", 
                    F.when(F.col("fare_amount") > 0, F.round((F.col("tip_amount") / F.col("fare_amount")) * 100, 2)).otherwise(0.0)) \
        .withColumn("year", F.year(F.col("pickup_datetime"))) \
        .withColumn("month", F.month(F.col("pickup_datetime")))

    print(f"[*] Writing Cleaned Silver Layer partitioned by Year and Month...")
    clean_silver_df.write \
        .mode("overwrite") \
        .partitionBy("year", "month") \
        .parquet(silver_output_path)

    print("\n[SUCCESS] PySpark Bronze & Silver ETL pipeline completed successfully.")
    spark.stop()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="PySpark Bronze/Silver ETL")
    parser.add_argument("--input-path", required=True, help="Input S3 or local path to raw parquet files")
    parser.add_argument("--bronze-output", required=True, help="Output S3 path for Bronze layer")
    parser.add_argument("--silver-output", required=True, help="Output S3 path for Silver layer")

    args = parser.parse_args()
    process_bronze_to_silver(args.input_path, args.bronze_output, args.silver_output)

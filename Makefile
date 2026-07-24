.PHONY: help install-dev tf-init tf-plan docker-build-pyspark docker-build-dbt run-pyspark-local dbt-run dbt-test

help:
	@echo "Enterprise Analytics Lakehouse Platform on Kubernetes (EAL-K8s) CLI Commands:"
	@echo "  make tf-init               - Initialize Terraform working directory"
	@echo "  make tf-plan               - Generate Terraform infrastructure execution plan"
	@echo "  make docker-build-pyspark  - Build local Docker image for PySpark ETL"
	@echo "  make docker-build-dbt      - Build local Docker image for dbt"
	@echo "  make run-pyspark-local     - Run PySpark ETL job locally using Python/Spark"
	@echo "  make dbt-run               - Execute dbt transformations locally"
	@echo "  make dbt-test              - Run dbt data assertions locally"

tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

docker-build-pyspark:
	docker build -t eal-k8s/pyspark-etl:latest -f docker/Dockerfile.pyspark .

docker-build-dbt:
	docker build -t eal-k8s/dbt-transformations:latest -f docker/Dockerfile.dbt .

run-pyspark-local:
	SPARK_LOCAL_DEV=true python src/pyspark/etl_bronze_silver.py \
		--input-path "s3a://nyc-tlc/trip-data/yellow_tripdata_2023-01.parquet" \
		--bronze-output "data/bronze/nyc_trips" \
		--silver-output "data/silver/nyc_trips"

dbt-run:
	cd src/dbt && dbt run --profiles-dir .

dbt-test:
	cd src/dbt && dbt test --profiles-dir .

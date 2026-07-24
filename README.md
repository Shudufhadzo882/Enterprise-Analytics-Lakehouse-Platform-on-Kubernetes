# Enterprise Analytics Lakehouse Platform on Kubernetes (EAL-K8s)

Production-ready Cloud-Native Lakehouse architecture designed for modern data engineering workloads on AWS EKS using Terraform, PySpark (Spark Operator), dbt, Apache Airflow, and GitHub Actions CI/CD.

---

## 🏗 Architecture Diagram

```text
[ Git Push / PR ] ──► [ GitHub Actions CI/CD ]
                             │
                             ├──► 1. Terraform Plan/Apply (EKS, S3, Snowflake/Redshift)
                             ├──► 2. Docker Build & Push (dbt / PySpark image to ECR)
                             └──► 3. Helm / kubectl Deploy to Kubernetes (EKS)
                                       │
                                       ▼
                     ┌──────────────────────────────────┐
                     │     Kubernetes Cluster (EKS)     │
                     │  ┌────────────────────────────┐  │
                     │  │ Airflow / Argo Workflows   │  │ (Orchestration)
                     │  └─────────────┬──────────────┘  │
                     │                │                 │
                     │  ┌─────────────▼──────────────┐  │
                     │  │ Spark Operator (PySpark)   │  │ (Heavy ETL Engine)
                     │  └─────────────┬──────────────┘  │
                     └────────────────┼─────────────────┘
                                      │
                                      ▼
                        [ S3 / Parquet Bronze & Silver ]
                                      │
                                      ▼
             [ dbt on K8s Job ] ──► [ Gold Warehouse Layer ] (Snowflake/Redshift/ClickHouse)
```

---

## 🌟 Key Components & Technologies

| Layer | Component | Description |
| :--- | :--- | :--- |
| **Infrastructure** | **AWS EKS & Terraform** | Modular IaC defining Kubernetes cluster, Spot node groups, VPC networking, and IAM IRSA policies. |
| **Storage (Medallion)** | **AWS S3 Buckets** | Bronze (raw parquet ingestion), Silver (cleaned & partitioned parquet), Gold (warehouse aggregates). |
| **ETL Engine** | **Apache Spark Operator** | Distributed PySpark engine running on EKS for heavy data cleansing and feature engineering. |
| **Orchestration** | **Apache Airflow** | DAG workflow management running on EKS via Helm with KubernetesPodOperator. |
| **Data Warehouse & dbt** | **dbt (DuckDB / Snowflake / Redshift)** | Data transformation layer building dimensional models, fact tables, and analytical marts. |
| **Containers & CI/CD** | **Docker & GitHub Actions** | Automated build, push to ECR, Terraform validation, and K8s manifests deployment. |

---

## 📂 Project Repository Structure

```text
├── .github/
│   └── workflows/
│       └── ci-cd.yml                # Automated Terraform, Docker Build/Push, and EKS Deploy
├── docker/
│   ├── Dockerfile.pyspark           # Container definition for PySpark ETL job
│   └── Dockerfile.dbt               # Container definition for dbt execution
├── k8s/
│   ├── airflow/
│   │   └── values.yaml              # Helm values for Apache Airflow deployment
│   ├── dbt/
│   │   └── dbt-job.yaml             # Kubernetes Job manifest for dbt runs
│   └── spark-operator/
│       └── spark-application.yaml   # SparkApplication CRD manifest for Spark on K8s
├── orchestration/
│   └── dags/
│       └── nyc_tlc_lakehouse_pipeline.py # Airflow DAG pipeline
├── src/
│   ├── dbt/                         # dbt transformations (staging, marts, tests)
│   │   ├── models/
│   │   │   ├── staging/stg_nyc_trips.sql
│   │   │   └── marts/
│   │   │       ├── dim_vendors.sql
│   │   │       ├── dim_payment_types.sql
│   │   │       ├── fct_trips.sql
│   │   │       └── mart_monthly_revenue.sql
│   │   ├── dbt_project.yml
│   │   └── profiles.yml
│   └── pyspark/                      # PySpark ETL processing scripts
│       ├── utils/
│       │   └── spark_session.py     # Configured PySpark session builder with S3A driver
│       └── etl_bronze_silver.py     # Main Bronze & Silver transformation job
├── terraform/                       # Infrastructure as Code
│   ├── main.tf                      # EKS, VPC, and S3 Buckets
│   ├── iam.tf                       # EKS IAM Roles for Service Accounts (IRSA)
│   ├── variables.tf                 # Environment variables
│   ├── outputs.tf                   # Exported outputs
│   └── providers.tf                 # Terraform provider definitions
├── Makefile                         # Developer CLI shortcuts
├── .gitignore                       # Git exclusion paths
└── README.md                        # Documentation
```

---

## 🚀 Quick Start Guide

### Prerequisites

- **Terraform** >= 1.5.0
- **AWS CLI v2** configured with proper IAM privileges
- **Docker Desktop**
- **kubectl** & **Helm**

### 1. Provision AWS Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### 2. Configure Local Kubernetes Access (`kubectl`)

```bash
aws eks update-kubeconfig --name eal-k8s-cluster --region us-east-1
```

### 3. Build & Push Docker Images

```bash
# Build PySpark container
make docker-build-pyspark

# Build dbt container
make docker-build-dbt
```

### 4. Deploy Apache Airflow & Spark Operator to EKS

```bash
# Install Spark Operator via Helm
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm install spark-operator spark-operator/spark-operator --namespace spark-operator --create-namespace --set webhook.enable=true

# Deploy Spark Application & dbt Job
kubectl apply -f k8s/spark-operator/spark-application.yaml
kubectl apply -f k8s/dbt/dbt-job.yaml
```

---

## 🧪 Local Testing & Verification

Run PySpark ETL locally:

```bash
make run-pyspark-local
```

Run dbt models and data assertions locally:

```bash
make dbt-run
make dbt-test
```


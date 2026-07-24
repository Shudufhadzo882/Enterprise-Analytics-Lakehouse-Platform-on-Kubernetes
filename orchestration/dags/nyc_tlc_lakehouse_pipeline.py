"""
Airflow DAG: Orchestrate EAL-K8s PySpark ETL & dbt Transformations on EKS
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.operators.python import PythonOperator
from kubernetes.client import models as k8s

default_args = {
    'owner': 'lakehouse-platform',
    'depends_on_past': False,
    'start_date': datetime(2023, 1, 1),
    'email_on_failure': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'nyc_tlc_lakehouse_pipeline',
    default_args=default_args,
    description='Orchestrates Spark Operator ETL and dbt warehouse modeling on EKS',
    schedule_interval='@daily',
    catchup=False,
)

# Step 1: Execute PySpark Job on EKS via Spark Operator Pod / KubernetesPodOperator
pyspark_etl_task = KubernetesPodOperator(
    task_id='run_pyspark_bronze_silver_etl',
    name='pyspark-etl-job',
    namespace='analytics',
    image='eal-k8s/pyspark-etl:latest',
    cmds=["python3", "/opt/spark/work-dir/etl_bronze_silver.py"],
    arguments=[
        "--input-path", "s3a://nyc-tlc/trip-data/yellow_tripdata_2023-01.parquet",
        "--bronze-output", "s3a://eal-k8s-lakehouse-bronze-prod/nyc_trips/",
        "--silver-output", "s3a://eal-k8s-lakehouse-silver-prod/nyc_trips/"
    ],
    service_account_name='spark-sa',
    is_delete_operator_pod=True,
    get_logs=True,
    dag=dag,
)

# Step 2: Execute dbt Gold Layer Transformations
dbt_transformations_task = KubernetesPodOperator(
    task_id='run_dbt_gold_transformations',
    name='dbt-gold-job',
    namespace='analytics',
    image='eal-k8s/dbt-transformations:latest',
    cmds=["dbt", "run", "--profiles-dir", "/usr/app/dbt"],
    service_account_name='spark-sa',
    is_delete_operator_pod=True,
    get_logs=True,
    dag=dag,
)

# Step 3: Run dbt Data Quality Assertions
dbt_test_task = KubernetesPodOperator(
    task_id='run_dbt_data_quality_tests',
    name='dbt-test-job',
    namespace='analytics',
    image='eal-k8s/dbt-transformations:latest',
    cmds=["dbt", "test", "--profiles-dir", "/usr/app/dbt"],
    service_account_name='spark-sa',
    is_delete_operator_pod=True,
    get_logs=True,
    dag=dag,
)

# DAG Pipeline Dependency Chain
pyspark_etl_task >> dbt_transformations_task >> dbt_test_task

import os
from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.dummy import DummyOperator
from airflow.contrib.operators.spark_submit_operator import SparkSubmitOperator

with DAG(
    dag_id="test_spark",
    start_date=datetime(2023,1,9),
    end_date=datetime(2023,1,10),
    schedule_interval="@daily") as dag:

    start_task = DummyOperator(task_id='start')

    save_to_warehouse = SparkSubmitOperator(
        task_id="save_to_warehouse",
        application="/usr/local/spark/app/save_to_warehouse.py",
        name="save_to_warehouse",
        conn_id="spark_connection", # Should be configured to use spark_master
        verbose=1,
        conf={"spark.master":"spark://spark:7077"},
        application_args=[],
        dag=dag
    )

    end_task = DummyOperator(task_id='end')

    start_task >> save_to_warehouse >> end_task


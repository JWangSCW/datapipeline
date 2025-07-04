import os
from datetime import datetime
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.operators.dummy import DummyOperator
from airflow.contrib.operators.spark_submit_operator import SparkSubmitOperator

AIRFLOW_HOME = os.environ.get("AIRFLOW_HOME", "/opt/airflow/")
HOME_DIRECTORY = os.path.expanduser('~')

# Only Italian data for now
URL_PREFIX = 'https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/' 
URL_TEMPLATE = URL_PREFIX + 'dpc-covid19-ita-andamento-nazionale-{{ execution_date.strftime(\'%Y%m%d\') }}.csv'
OUTPUT_FILE_TEMPLATE = '/usr/share/covid_data/raw/{{ execution_date.strftime(\'%Y\') }}/{{ execution_date.strftime(\'%m\') }}/{{ execution_date.strftime(\'%d\') }}/ita_cases_{{ execution_date.strftime(\'%Y%m%d\') }}.csv'

with DAG(
    dag_id="get_cases_data",
    start_date=datetime(2022,12,20),
    end_date=datetime(2023,1,10),
    max_active_runs = 3,
    schedule_interval="@daily") as dag:

    start_task = DummyOperator(task_id='start')

    download_data_task = BashOperator(
        task_id='download_data',
        bash_command=f'curl -sSL --create-dirs -o {OUTPUT_FILE_TEMPLATE} {URL_TEMPLATE}'
    )

    merge_data_task = SparkSubmitOperator(
        task_id="merge_data",
        application="/usr/local/spark/app/merge_data.py",
        name="merge_data",
        conn_id="spark_connection", # Should be configured to use spark_master
        verbose=1,
        application_args=[],
        dag=dag
    )

    save_to_warehouse = SparkSubmitOperator(
        task_id="save_to_warehouse",
        application="/usr/local/spark/app/save_to_warehouse.py",
        name="save_to_warehouse",
        conn_id="spark_connection", # Should be configured to use spark_master
        verbose=1,
        application_args=[],
        dag=dag
    )

    end_task = DummyOperator(task_id='end')

    start_task >> download_data_task >> merge_data_task >> save_to_warehouse >> end_task


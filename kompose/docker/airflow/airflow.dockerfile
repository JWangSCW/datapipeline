FROM apache/airflow:2.5.0

ENV AIRFLOW_HOME=/opt/airflow

USER root
RUN apt-get update -qq && apt-get install vim curl wget default-jre -qqq

USER $AIRFLOW_UID

# RUN airflow connections add 'spark_connection' --conn-json '{"conn_type": "spark","host": "spark://spark","port": 7077}'

# RUN curl https://jdbc.postgresql.org/download/postgresql-42.5.4.jar --create-dirs -o ~/spark/postgresql-42.5.4.jar

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


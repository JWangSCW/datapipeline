FROM apache/zeppelin:0.10.1

ENV BASE_URL=https://archive.apache.org/dist/spark/
ENV SPARK_VERSION=3.1.3
ENV HADOOP_VERSION=3.2

USER root

RUN wget -nc ${BASE_URL}/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz --progress=bar:force && \
    tar xvf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
    rm -r -f /spark && \
    mkdir -p /spark && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/* /spark/ && \
    mkdir -p /sample-data

RUN apt-get update && apt-get install -y python3

# Install python 3.9 with pyenv and make it global

RUN pip install pyspark==3.1.3 findspark ipython



ENV SPARK_HOME "/spark"
ENV PYSPARK_PYTHON "/usr/bin/python3.8"
ENV PYSPARK_DRIVER_PYTHON "/usr/bin/python3.8"
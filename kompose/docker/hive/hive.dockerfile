FROM apache/hive:3.1.3

USER root

RUN apt-get update && \
    apt-get install -y postgresql-client iputils-ping telnet lsof netcat

COPY ./hivemetastore-site.xml /opt/hive/conf/hivemetastore-site.xml
COPY ./hiveserver2-site.xml /opt/hive/conf/hiveserver2-site.xml
COPY ./core-site.xml /opt/hive/conf/core-site.xml
COPY ./hdfs-site.xml /opt/hive/conf/hdfs-site.xml
COPY init-hive-db.sh /opt/hive/init/
RUN chmod +x /opt/hive/init/init-hive-db.sh

EXPOSE 9083 10000 10002
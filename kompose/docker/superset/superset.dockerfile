FROM apache/superset:2.1.0

USER root

RUN apt-get update && apt-get install -y zip unzip
RUN pip install pyhive requests bs4

ENV ADMIN_USERNAME $ADMIN_USERNAME
ENV ADMIN_EMAIL $ADMIN_EMAIL
ENV ADMIN_PASSWORD $ADMIN_PASSWORD

COPY ./*.sh /superset-init.sh
RUN chmod +x /superset-init.sh

COPY ./database_export /database_export
RUN zip -r /database_export.zip /database_export

COPY ./dashboard_export /dashboard_export
RUN zip -r /dashboard_export.zip /dashboard_export

COPY ./superset_config.py /app/
ENV SUPERSET_CONFIG_PATH /app/superset_config.py

USER superset
ENTRYPOINT [ "/superset-init.sh" ]

# hive://hive@hive-server:10000/default
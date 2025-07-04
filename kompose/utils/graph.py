from diagrams import Diagram, Cluster
from diagrams.onprem.vcs import Github
from diagrams.generic.storage import Storage
from diagrams.onprem.analytics import Spark, Hive, Superset, Hadoop
from diagrams.programming.language import Python
from diagrams.onprem.workflow import Airflow
from diagrams.custom import Custom

graph_attr = {
    "label": ""
}

with Diagram("Pipeline", show=False, graph_attr=graph_attr):
    airflow = Airflow("Orchestrator")
    with Cluster("Pipeline"):
        source = Github("Protezione Civile")
        storage = Storage("Local CSV")
        merge_data = Spark("Merge data")
        hadoop_storage = Hadoop("Parquet on HDFS")
        save_to_warehouse = Spark("Save to warehouse")
        hive_warehouse = Hive("Data warehouse")
        superset = Superset("Data visualization")
        zeppelin = Custom("Data exploration", "./logos/zeppelin_classic_logo.png")
        source >> storage >> merge_data >> hadoop_storage >> save_to_warehouse >> hive_warehouse
        hive_warehouse >> superset
        hive_warehouse >> zeppelin
    airflow >> source

    


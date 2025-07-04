# covid_line: A pipeline for COVID-19 data
This project aims to be a full data pipeline for italian COVID-19 data, starting from the extraction of raw data up to the presentation in form of dashboard. It is built upon docker, allowing anyone to play with it with no (or not much) additional setup.

## What this project is
This project is intended to emulate a data engineerging and analytics pipeline with a rather simple dataset. The approach will try to be as solid as possible, and even though one could argue that some steps are not needed for the final results, I tried to include them for the sake of completness of the process.

## What this project is not
The pipeline works and the data related stuff tries to be as solid as possible, but this project is not intended to be a fully production ready development, especially in the DevOps realm. The configuration of the various tools used is done in order to make them work, not to make them secure or production ready, so keep this in mind while you explore.

# Tools
As for tools, I chose to use only Apache tools, for different reasons:
- most of them are really solid tools used in different production environments
- I don't usually use them in my daily work, as I am working with different technologies
- they are open source
No tools is really production ready, even though the structure of them is fine I advise againts copying this setup for production purposes. Here is a list of all the tools that are included and what they are used for:
- Apache Airflow: orchestrator for all the workflows
    - GUI can be accessed at [http://localhost:8080/](http://localhost:8080/)
    - DAG files are stored into /dags which is then mounted to the docker container
    - The environment uses LocalExecutor so no additional worker is defined
- Apache Spark: all data operations are run as Spark jobs
    - Master GUI can be accessed at [http://localhost:4040/](http://localhost:4040/)
    - Spark scripts are stored into /spark/app which is then mounted to the docker container
    - The environment uses one master and one worker
- Apache Hadoop: used for HDFS support for Hive
    - GUI can be accessed at [http://localhost:50075/](http://localhost:50075/)
    - The environment emulates uses one namenode and one datanode
    - If you have issues when starting the cluster, please give 777 permissions to the local datanode and namenode folders
    - If you get issues about the NameNode not being formatted please delete everything inside the local folders, modify the environment section as 
        ```yml
        #ENSURE_NAMENODE_DIR: "/hadoop/dfs/name"
        ENSURE_NAMENODE_DIR: "/tmp/hadoop-root/dfs/name"
        ```
        run ```docker compose --profile hadoop up ```, when the cluster successfully starts bring it down and change the environment back to
        ```yml
        ENSURE_NAMENODE_DIR: "/hadoop/dfs/name"
        #ENSURE_NAMENODE_DIR: "/tmp/hadoop-root/dfs/name"
        ```
- Apache Hive: data warehousing over HDFS
    - The environment uses a main server with a standalone metastore, with PostgreSQL as a backend
- Apache Superset: data visualization and dashboarding
    - GUI can be accessed at [http://localhost:8088/](http://localhost:8088/)
    - Superset files are stored into /docker_entrypoiunts/superset/dashboard_export, which is copied into the container, zipped and imported using the Superset CLI
    - This service is kept out of the pipeline for performance's sake, but it can be started running ```docker compose --profile superset up ``` when the rest of the pipeline is running
- Apache Zeppelin: data exploration and notebooks
    - GUI can be accessed at [http://localhost:2020/](http://localhost:2020/)
    - This service is kept out of the pipeline as it has no place in the pipeline itself, it's just there for data exploration and notebooks usage, but it can be started running ```docker compose --profile zeppelin up ``` when the rest of the pipeline is running

# Architecture
In this section I will go throught the architecture of the pipeline, starting from the general overview and then going into more details.
## Overview
The raw data is extracted daily from the Protezione Civile's github repository, and stored in a raw folder, from which it is extracted, modified and stored as Parquet files in a data lake (which is currently local).
Data is then moved onto an Hive data warehouse from which it can be queried and visualized using Superset.
![Pipeline representation.](/utils/pipeline.png)

### Data extraction
The data comes directly from the Protezione Civile's [Github Repository](https://github.com/pcm-dpc/COVID-19). They host a summary file containing all data directly, but since the aim of the project is to emulate a production pipeline as much as possible, I decided to extract the data from the daily uploads, even though this means that the data is really small as each file contains only one line.
The pipeline is built with the possibility to be expanded with other countries' data in the future in mind (that's why the step is called merge_data).

### Data loading
The data is stored as raw csv files in the raw folder, with the following folder structure.
```
Raw folder
|    
└-- Year folder  
    |    
    └-- Month folder
        |    
        └-- Day folder
            |
            └-- countrycode_cases_date.csv  
```
The data is then read from the daily folders and grouped into daily parquet files, partitioned by country code and stored in HDFS, with the following folder structure.
```
Pq folder
|    
└-- Year folder  
    |    
    └-- Month folder
        |    
        └-- Day folder
            |    
            └-- cases_date.parquet
```

The maximum granularity is chosen, in order to easily reload onde day's data when needed. This is done becuase the same pipeline could be adapted to different datasets with few modifcations (e.g.: retail transactions). For the current example, as the data is very limited, and would be very limited even if all the countries were to be included, the convenience gain is minimal, but still I prefer this kind of design.

This folder structure will be kept even for future data (for example: vaccination).

As of right now there data comes only from one country, but the pipeline is designed with the idea that it could be upgraded to extract data from other countries as well.

### Data warehousing
In order to support different analytical tasks and SQL-like queries, raw data is stored inside Hive.
The data is loaded into a "cases" table, overwriting data for the same date but leaving all the rest of the table untouched.
The table structure is very simple, and can be seen below.
| column_name | data_type | description |
| --- | --- | --- |
| collection_date | date | The date to which the measurement refers to. |
| collection_id | string | The collection id, it is an hash of the concatenation of the country_cod and the collection_date |
| country_cod | string | The country code to which the measurement refers to. |
| new_positive_cases | int | The number of positive cases for the day. |

### Data visualization
The data visualization tool of choice is Apache Superset, which is connected directly to the Hive Database.
Dashboards can be defined as YAML files and later imported through the CLI, but as of right now the workflow I follow is:
- edit the dashboard/charts using Superset UI
- export the dashboard/chart using Superset API/CLI tool
- unzip the archive and store the data inside the entrypoints folder (the unzipping part is not necessary and not advised from the Superset team, but it's more clear for the repo)
- in the superset dockerfile, import the export folder and zip it for import into superset
- in the superset entrypoint, execute the Superset CLI tool to import the exported zip file
All the files can be found under:
docker_entrypoints
|    
└-- superset  
    |    
    └-- dashboard/database_export

# How to run
Running the pipeline is pretty simple, you just have to run ```docker compose --profile pipeline --build up ```. When the containers are fully oeprational you can access the different user interfaces at the links provided.
If you want you can also start the visualisation and explorations containers by running ```docker compose --profile superset --build up ``` and ```docker compose --profile zeppelin --build up ``` respectively.
By default the data is limited to just a very small window, in order to keep the performance and space requirements low, but you can simply modify the start_date and end_date parameters for the DAGs.
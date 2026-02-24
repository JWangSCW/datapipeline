terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "scaleway" {
  access_key = var.access_key
  secret_key = var.secret_key
  project_id = var.project_id
  region     = var.region
}



resource "scaleway_vpc" "demo" {
  name = "vpc-demo-1"
  tags = ["demo-1"]
}


resource "scaleway_vpc_private_network" "demo" {
  name   = "kapsule-private-net-demo1"
  region = "fr-par"
}


resource "scaleway_k8s_cluster" "demo" {
  name                        = "cluster-demo-1"
  type                        = "kapsule"
  region                      = "fr-par"
  version                     = "1.35.1"
  cni                         = "cilium"
  tags                        = ["demo-1"]
  private_network_id          = scaleway_vpc_private_network.demo.id
  delete_additional_resources = true
}


resource "scaleway_k8s_pool" "demo" {
  for_each = {
    "fr-par-1" = "PRO2-XXS",
    "fr-par-2" = "PRO2-XXS"
  }
  name                   = "pool-${each.key}-demo-1"
  zone                   = each.key
  tags                   = ["demo-1"]
  cluster_id             = scaleway_k8s_cluster.demo.id
  node_type              = each.value
  size                   = 1
  autoscaling            = false
  autohealing            = false
  container_runtime      = "containerd"
  root_volume_size_in_gb = 32
}


provider "kubernetes" {
  host                   = scaleway_k8s_cluster.demo.kubeconfig[0].host
  token                  = scaleway_k8s_cluster.demo.kubeconfig[0].token
  cluster_ca_certificate = base64decode(scaleway_k8s_cluster.demo.kubeconfig[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = scaleway_k8s_cluster.demo.kubeconfig[0].host
    token                  = scaleway_k8s_cluster.demo.kubeconfig[0].token
    cluster_ca_certificate = base64decode(scaleway_k8s_cluster.demo.kubeconfig[0].cluster_ca_certificate)
  }
}

resource "scaleway_rdb_instance" "demo" {
  name           = "pg-demo-1"
  node_type      = "db-dev-s"
  engine         = "PostgreSQL-15"
  is_ha_cluster  = false
  disable_backup = false
  user_name      = var.pg_username
  password       = var.pg_password
}

resource "scaleway_rdb_database" "demo" {
  instance_id = scaleway_rdb_instance.demo.id
  name        = var.pg_table
}
resource "scaleway_rdb_privilege" "demo" {
  instance_id   = scaleway_rdb_instance.demo.id
  user_name     = scaleway_rdb_instance.demo.user_name
  database_name = scaleway_rdb_database.demo.name
  permission    = "all"
}


resource "scaleway_datawarehouse_deployment" "demo" {
  name          = "dwh-demo-1"
  version       = "v25"
  replica_count = 1
  cpu_min       = 2
  cpu_max       = 4
  ram_per_cpu   = 4
  password      = var.dwh_password
}

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
}



resource "helm_release" "airflow" {
  name             = "airflow"
  repository       = "https://airflow.apache.org"
  chart            = "airflow"
  namespace        = "airflow"
  create_namespace = true
  version          = "1.18.0"

  values = [templatefile("${path.module}/values.yaml.tftpl", {
    pg_username = var.pg_username
    pg_password = var.pg_password
    pg_host     = scaleway_rdb_instance.demo.load_balancer[0].ip
    pg_port     = var.pg_port
    pg_table    = var.pg_table
    git_repo    = var.dbt_repo
  })]

  set {
    name  = "dags.gitSync.enabled"
    value = "true"
  }
  set {
    name  = "dags.gitSync.repo"
    value = var.dbt_repo
  }
  set {
    name  = "dags.gitSync.branch"
    value = "main"
  }
  set {
    name  = "airflowHome"
    value = "/opt/airflow"
  }

  set {
    name  = "config.core.dags_folder"
    value = "/opt/airflow/dags/repo"
  }
  set {
    name  = "dags.persistence.enabled"
    value = "false"
  }
  set {
    name  = "envFromSecret"
    value = kubernetes_secret.dwh_connection.metadata[0].name
  }

  depends_on = [
    scaleway_k8s_pool.demo,
    kubernetes_secret.dwh_connection
  ]
}

resource "kubernetes_secret" "dwh_connection" {
  metadata {
    name      = "dwh-connection-secret"
    namespace = "airflow"
  }
  data = {
    "AIRFLOW_CONN_CLICKHOUSE_DEFAULT" = "clickhouse://${var.dwh_username}:${var.dwh_password}@${element(split("/", scaleway_datawarehouse_deployment.demo.id), 1)}.dtwh.${var.region}.scw.cloud:${var.dwh_port}/${var.dwh_table}?secure=1"
  }
  type = "Opaque"

  depends_on = [scaleway_datawarehouse_deployment.demo]
}

resource "kubernetes_secret" "postgres_connection" {
  metadata {
    name      = "pg-connection-secret"
    namespace = "airflow"
  }

  data = {
    "AIRFLOW_CONN_POSTGRES_SOURCE" = "postgresql://${var.pg_username}:${var.pg_password}@${scaleway_rdb_instance.demo.load_balancer[0].ip}:${var.pg_port}/${var.pg_table}"
  }

  type       = "Opaque"
  depends_on = [scaleway_rdb_database.demo]
}

# resource "kubernetes_persistent_volume_claim" "airflow_dags_pvc" {
#   metadata {
#     name      = "airflow-dags-pvc"
#     namespace = "airflow"
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "5Gi"
#       }
#     }
#     storage_class_name = "sbs-default"
#   }
# }

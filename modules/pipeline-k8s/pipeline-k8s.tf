terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

resource "scaleway_vpc" "vpc" {
  name = "pipeline-vpc"
  tags = ["terraform", "k8s"]
}

resource "scaleway_vpc_private_network" "pn" {
  vpc_id = scaleway_vpc.vpc.id
  name   = "pipeline-regional-private"
  tags = ["terraform", "k8s"]

}

resource "scaleway_k8s_cluster" "cluster" {
  name                        = "pipeline-cluster"
  version                     = "1.30.2"
  cni                         = "cilium"
  private_network_id          = scaleway_vpc_private_network.pn.id
  delete_additional_resources = true
  tags = ["terraform", "k8s"]
}

resource "scaleway_k8s_pool" "pool-multi-az" {
  for_each = {
    "fr-par-1" = "DEV1-L"
    "fr-par-2" = "DEV1-L",
    "fr-par-2" = "DEV1-L"
  }
  name                   = "pool-${each.key}"
  zone                   = each.key
  tags = ["terraform", "k8s"]
  cluster_id             = scaleway_k8s_cluster.cluster.id
  node_type              = each.value
  size                   = 1
  min_size               = 1
  max_size               = 2
  autoscaling            = true
  autohealing            = true
  container_runtime      = "containerd"
  root_volume_size_in_gb = 40
  public_ip_disabled     = false
}

resource "scaleway_rdb_instance" "pipeline-airflow-postgre-database-instance" {
  name           = "pipeline-airflow-postgre-database-instance"
  node_type      = "DB-DEV-S"
  engine         = "PostgreSQL-15"
  is_ha_cluster  = true
  disable_backup = true
  user_name      = "my_initial_user"
  password       = "thiZ_is_v&ry_s3cret"
  private_network {
    pn_id  = scaleway_vpc_private_network.pn.id
    ip_net = "172.16.20.4/22"   # IP address within a given IP network
    # enable_ipam = false
  }
}

resource "scaleway_rdb_database" "pipeline-airflow-postgre-database" {
  instance_id = scaleway_rdb_instance.pipeline-airflow-postgre-database-instance.id
  name        = "pipeline-airflow-postgre-database"
}


resource "scaleway_rdb_instance" "pipeline-hive-postgre-database-instance" {
  name           = "pipeline-hive-postgre-database-instance"
  node_type      = "DB-DEV-S"
  engine         = "PostgreSQL-15"
  is_ha_cluster  = true
  disable_backup = true
  user_name      = "my_initial_user"
  password       = "thiZ_is_v&ry_s3cret"
  private_network {
    pn_id  = scaleway_vpc_private_network.pn.id
    ip_net = "172.16.20.5/22"   # IP address within a given IP network
    # enable_ipam = false
  }
}

resource "scaleway_rdb_database" "pipeline-hive-postgre-database" {
  instance_id = scaleway_rdb_instance.pipeline-hive-postgre-database-instance.id
  name        = "pipeline-hive-postgre-database"
}


// Activate Cockpit in the same project than the VPC
resource "scaleway_cockpit" "main" {
  project_id = scaleway_vpc.vpc.project_id
}

resource "scaleway_cockpit_grafana_user" "main" {
  project_id = scaleway_cockpit.main.project_id
  login      = "emaudet"
  role       = "editor"
}

provider "helm" {
  kubernetes {
    host  = scaleway_k8s_cluster.cluster.kubeconfig[0].host
    token = scaleway_k8s_cluster.cluster.kubeconfig[0].token
    cluster_ca_certificate = base64decode(
      scaleway_k8s_cluster.cluster.kubeconfig[0].cluster_ca_certificate
    )
  }
}
/*
resource "helm_release" "nginx_ingress" {
  name      = "nginx-ingress"
  namespace = "ingress-nginx"
  create_namespace = true
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  set {
    name  = "controller.ingressClassResource.default"
    value = true
  }
  set {
    name  = "controller.ingressClassResource.enabled"
    value = true
  }
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
}

resource "helm_release" "cert-manager" {
  repository       = "https://charts.jetstack.io"
  chart = "cert-manager"
  name             = "cert-manager"
  create_namespace = true
  namespace        = "cert-manager"
  set {
    name  = "crds.enabled"
    value = true
  }
}*/

resource "helm_release" "pipeline-helm-release" {
  chart            = "${path.module}/../../kompose/pipeline-helm "
  name             = "pipeline-helm-release"
  create_namespace = true
  namespace        = "pipeline-namespace"
}

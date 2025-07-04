# main.tf
provider "scaleway" {
  project_id = "d4e65cad-97cc-4dab-9a27-a62929d68dd3"
  zone       = "fr-par-2"
  region     = "fr-par"
}

terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}


module "pipeline-k8s" {
  source = "./modules/pipeline-k8s"
}

module "pipeline-one-vm" {
  source = "./modules/pipeline-one-public-vm"
}
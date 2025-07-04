terraform {
  required_providers {
    scaleway = {
      source = "scaleway/scaleway"
    }
  }
  required_version = ">= 0.13"
}

// 1 public IP
resource "scaleway_instance_ip" "public_ip" {}

// Security group with some TCP ports opened in input, et every ports opened in output
resource "scaleway_instance_security_group" "my-security-group" {
  name = "SG-VM-docker"
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  // SSH (port configured in cloud-init)
  inbound_rule {
    action = "accept"
    port   = "2201"
  }
  // HTTP : potentially useful for Letsencrypt
  inbound_rule {
    action = "accept"
    port   = "80"
  }
  // HTTPS
  inbound_rule {
    action = "accept"
    port   = "443"
  }
  // Airflow GUI
  inbound_rule {
    action = "accept"
    port   = "8080"
  }
  // Spark GUI
  inbound_rule {
    action = "accept"
    port   = "4040"
  }
  // Hadoop GUI
  inbound_rule {
    action = "accept"
    port   = "9870"
  }
  // Superset GUI
  inbound_rule {
    action = "accept"
    port   = "8088"
  }
  // Zeppelin GUI
  inbound_rule {
    action = "accept"
    port   = "2020"
  }

  //VNC 5901 Or XRDP (Microsoft remote desktop) 3389
  #  inbound_rule {
  #    action = "accept"
  #    port   = "3389"
  #  }
}

// 1 VM
resource "scaleway_instance_server" "my-instance" {
  type                  = "DEV1-L"
  image                 = "ubuntu_noble"
  tags                  = ["terraform instance", "docker-vm"]
  ip_id                 = scaleway_instance_ip.public_ip.id
  name = "VM-docker"

  // Security group
  security_group_id = scaleway_instance_security_group.my-security-group.id
  # When the VM image is booted, this script (cloud-init.yml) is launched.
  user_data = {
    cloud-init = file("${path.module}/../../cloud-init.yml")
  }
}
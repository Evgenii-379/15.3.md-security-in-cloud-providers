terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.zone
}

resource "yandex_storage_bucket" "image_bucket" {
  access_key = var.yc_access_key
  secret_key = var.yc_secret_key

  bucket     = var.bucket_name
  acl        = "public-read"
}

resource "yandex_storage_object" "image_file" {
  access_key = var.yc_access_key
  secret_key = var.yc_secret_key

  bucket = yandex_storage_bucket.image_bucket.bucket
  key    = "image.jpg"
  source = "data/image.jpg"
  acl    = "public-read"
}

resource "yandex_kms_symmetric_key" "object_key" {
  name              = "bucket-encryption-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  folder_id         = var.yc_folder_id
}

resource "yandex_vpc_network" "network" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["10.1.0.0/24"]
}

resource "yandex_compute_instance_group" "lamp_group" {
  name               = "lamp-group"
  folder_id          = var.yc_folder_id
  service_account_id = var.service_account_id

  instance_template {
    platform_id = "standard-v2"
    resources {
      cores  = 2
      memory = 2
      core_fraction = 5
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit" # LAMP
        size = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network.id
      subnet_ids = [yandex_vpc_subnet.subnet.id]
      nat        = true
    }

    scheduling_policy {
      preemptible = true
    }

    metadata = {
      user-data = <<EOF
#!/bin/bash
cat <<HTML > /var/www/html/index.html
<html>
  <body>
    <h1>Hello from LAMP group</h1>
    <div style="text-align: center;">
    <img src="https://${var.bucket_name}.storage.yandexcloud.net/image.jpg" width="30%" />
  </body>
</html>
HTML
EOF


ssh-keys  = "ubuntu:${var.public_ssh_key}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
  }

  health_check {
    tcp_options {
      port = 80
    }
  }
}

resource "yandex_lb_target_group" "tg" {
  name      = "target-group"
  region_id = var.region

  target {
    subnet_id = yandex_vpc_subnet.subnet.id
    address   = yandex_compute_instance_group.lamp_group.instances[0].network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "nlb" {
  name        = "nlb"
  region_id   = var.region

  listener {
    name = "http"
    port = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

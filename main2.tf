variable env_prefix {}
variable hostname_blocks {}

#variable vpc_cidr_block {}
#variable avail_zone {}
#variable instance_ip {}
#variable ipaddr_blocks {}

data "template_file" "metadata" {
  template = file("./meta.yaml")
}

#--- Группа ВМ с балансировщиком ---


resource "yandex_compute_instance_group" "ig-1" {
  name                = "fixed-ig-with-balancer"
  folder_id           = "b1g6k2i3lobiesnh55af"
  service_account_id  = "aje2271kkvefi1el32vv"
  #deletion_protection = "<защита_от_удаления:_true_или_false>"
  instance_template {
    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd82nvvtllmimo92uoul"
      }
    }

    network_interface {
      network_id = "${yandex_vpc_network.network-1.id}"
      subnet_ids = ["${yandex_vpc_subnet.subnet-1.id}"]
      nat       = true
    }

#    metadata = {
#      user-data = "${file("./meta.yaml")}"
#    }
    metadata = {
      user-data = data.template_file.metadata.rendered
    }  

    scheduling_policy {
      preemptible = true
    }
  }
  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "target-group"
    target_group_description = "load balancer target group"
  }
}


#-- создание балансировщика ----

resource "yandex_lb_network_load_balancer" "lb-1" {
  name = "network-load-balancer-1"

  listener {
    name = "network-load-balancer-1-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

output "external_ip_address_lb" {
  value = [
    for listener in yandex_lb_network_load_balancer.lb-1.listener :
    listener.external_address_spec
  ]
}

output "external_ip_addresses" {
  value = yandex_compute_instance_group.ig-1.instances.*.network_interface.0.nat_ip_address
}

output "internal_ip_addresses" {
  value = yandex_compute_instance_group.ig-1.instances.*.network_interface.0.ip_address
}
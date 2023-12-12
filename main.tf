variable env_prefix {}
variable hostname_blocks {}

#variable vpc_cidr_block {}
#variable avail_zone {}
#variable instance_ip {}
#variable ipaddr_blocks {}

#---- vms --------------

resource "yandex_compute_instance" "vm" {
  
  count=2
  name = "${var.env_prefix[count.index]}-${count.index}"
  hostname = "${var.hostname_blocks[count.index]}-${count.index}"

  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  zone                      = local.zone

  resources {
    core_fraction = 5
    cores  = "2"
    memory = "2"
  }

  boot_disk {
    initialize_params {
      image_id = "fd82nvvtllmimo92uoul"   #ubuntu
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

  scheduling_policy {
  preemptible = true
   }

#  metadata = {
#    ssh-keys = "<имя_пользователя>:<содержимое_SSH-ключа>"
#  }
 metadata = {
    user-data = "${file("./meta.yaml")}"
  }

}



#-------- создание целевой группы -------

resource "yandex_lb_target_group" "my-target-group-resource" {
  name      = "my-target-group"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance.vm
    content {
      subnet_id = yandex_vpc_subnet.subnet-1.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}


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
#    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id
    target_group_id = yandex_lb_target_group.my-target-group-resource.id

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


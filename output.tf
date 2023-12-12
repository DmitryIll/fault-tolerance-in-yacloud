output "app_external-ip" {
   value="${yandex_compute_instance.vm[*].network_interface.0.nat_ip_address}"
}

output "internal-ip" {
   value="${yandex_compute_instance.vm[*].network_interface.0.ip_address}"
}


#output "ip2" {
#   value="${yandex_compute_instance.vm-1.network_interface.0.ip_address}"
#}



#output "external_ip_addresses" {
#  value = yandex_compute_instance_group.ig-1.instances.*.network_interface.0.nat_ip_address
  # value = [
  #   for instance_template in yandex_compute_instance_group.ig-1.instance_template :
  #   instance_template.network_interface.0.nat_ip_address
  # ]
#}


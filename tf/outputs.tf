output "ipv4_address" {
  value = "${digitalocean_floating_ip.registry_floating_ip.urn}"
}

output "registry-uri" {
  value = "${digitalocean_record.registry_record.fqdn}"
}

output "registry-dashboard-uri" {
  value = "${digitalocean_record.registry_dashboard_record.fqdn}"
}

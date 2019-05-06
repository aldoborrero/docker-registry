provider "digitalocean" {
  token             = "${var.digitalocean_token}"
  spaces_access_id  = "${var.spaces_access_id}"
  spaces_secret_key = "${var.spaces_secret_key}"
}

data "template_file" "docker_compose" {
  template = "${file("${path.module}/../docker-compose.yml")}"

  vars {
    registry_uri           = "${var.registry_subdomain}.${var.domain}"
    registry_dashboard_uri = "${var.registry_dashboard_subdomain}.${var.domain}"
    acme_email             = "${var.acme_email}"
    spaces_access_id       = "${var.spaces_access_id}"
    spaces_secret_key      = "${var.spaces_secret_key}"
    spaces_name            = "${digitalocean_spaces_bucket.registry_volume.name}"
    spaces_region          = "${digitalocean_spaces_bucket.registry_volume.region}"
    http_auth_enabled      = "${var.http_auth_enabled}"
    http_auth_user         = "${var.http_auth_user}"
    http_auth_password     = "${var.http_auth_password}"
  }
}

resource "digitalocean_tag" "registry_tags" {
  name = "${var.registry_tags}"
}

resource "digitalocean_spaces_bucket" "registry_volume" {
  name          = "${var.spaces_name}"
  region        = "${var.spaces_region}"
  force_destroy = true
}

resource "digitalocean_droplet" "registry_droplet" {
  image              = "${var.image}"
  size               = "${var.size}"
  region             = "${var.region}"
  count              = 1
  backups            = false
  ipv6               = false
  private_networking = false
  name               = "${format("%s-%s", var.name, var.region)}"
  ssh_keys           = "${var.ssh_keys_ids}"
  tags               = ["${digitalocean_tag.registry_tags.id}"]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = "${file("${var.ssh_key}")}"
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/registry/docker/traefik",
    ]
  }

  provisioner "file" {
    content     = "${data.template_file.docker_compose.rendered}"
    destination = "/opt/registry/docker-compose.yml"
  }

  provisioner "file" {
    source     = "${path.module}/../docker/traefik/Dockerfile"
    destination = "/opt/registry/docker/traefik/Dockerfile"
  }

  provisioner "file" {
    source     = "${path.module}/../docker/traefik/traefik.tmpl.toml"
    destination = "/opt/registry/docker/traefik/traefik.tmpl.toml"
  }
}

resource "digitalocean_floating_ip" "registry_floating_ip" {
  droplet_id = "${digitalocean_droplet.registry_droplet.id}"
  region     = "${digitalocean_droplet.registry_droplet.region}"
}

resource "digitalocean_domain" "registry_domain" {
  name = "${var.domain}"
}

resource "digitalocean_record" "registry_record" {
  domain = "${digitalocean_domain.registry_domain.name}"
  type   = "A"
  ttl    = 600
  name   = "${var.registry_subdomain}"
  value  = "${digitalocean_floating_ip.registry_floating_ip.ip_address}"
}

resource "digitalocean_record" "registry_dashboard_record" {
  domain = "${digitalocean_domain.registry_domain.name}"
  type   = "A"
  ttl    = 600
  name   = "${var.registry_dashboard_subdomain}"
  value  = "${digitalocean_floating_ip.registry_floating_ip.ip_address}"
}

resource "digitalocean_firewall" "registry_fw" {
  name        = "registry-fw"
  tags        = ["${digitalocean_tag.registry_tags.id}"]
  droplet_ids = ["${digitalocean_droplet.registry_droplet.id}"]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["${var.ssh_allowed_ips}"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

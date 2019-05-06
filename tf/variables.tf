variable "digitalocean_token" {}

variable "spaces_access_id" {}

variable "spaces_secret_key" {}

variable "name" {
  default = "registry"
}

variable "spaces_name" {
  default = "registry-volume"
}

variable "image" {
  default = "docker-18-04"
}

variable "size" {
  default = "s-1vcpu-1gb"
}

variable "region" {
  default = "sfo2"
}

variable "spaces_region" {
  default = "sfo2"
}

variable "ssh_keys_ids" {
  default = []
}

variable "ssh_key" {
  default = "~/.ssh/id_rsa"
}

variable "ssh_allowed_ips" {
  default = ["0.0.0.0/0", "::/0"]
}

variable "registry_tags" {
  default = "registry"
}

variable "domain" {}

variable "registry_subdomain" {
  default = "registry"
}

variable "registry_dashboard_subdomain" {
  default = "dashboard"
}

variable "acme_email" {}

variable "http_auth_enabled" {
  default = "false"
}

variable "http_auth_user" {
  default = ""
}

# Generate password with htpasswd: htpasswd -nb $user $password
variable "http_auth_password" {
  default = ""
}

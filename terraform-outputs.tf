output "bosh-bastion-hostname" {
  value = "${module.terraform-gcp-bosh.bosh-bastion-hostname}"
}

output "bosh-bastion-public-ip" {
  value = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
}

output "nat-gateway-ips" {
  value = ["${module.terraform-gcp-bosh.nat-gateway-ips}"]
}

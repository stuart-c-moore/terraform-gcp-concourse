resource "google_compute_subnetwork" "concourse" {
  name = "${var.prefix}-concourse"
  ip_cidr_range = "10.244.15.0/30"
  network = "${module.terraform-gcp-bosh.bosh-network-link}"
}

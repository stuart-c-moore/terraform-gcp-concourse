resource "google_compute_subnetwork" "concourse" {
  name = "${var.prefix}-concourse-${var.region}"
  ip_cidr_range = "${var.concourse-cidr}"
  network = "${module.terraform-gcp-bosh.bosh-network-link}"
}

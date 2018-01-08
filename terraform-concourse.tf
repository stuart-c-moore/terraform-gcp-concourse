resource "google_compute_subnetwork" "concourse" {
  name = "${var.prefix}-concourse-${var.region}"
  ip_cidr_range = "${var.concourse-cidr}"
  network = "${module.terraform-gcp-bosh.bosh-network-link}"
}

resourse "null_resource" "bosh-bastion" {
  provisioner "file" {
    source = "${path.module}/files/bosh-bastion/"
    destination = "${var.home}/"
    connection {
      user = "vagrant"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
}

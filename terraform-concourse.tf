resource "google_compute_subnetwork" "concourse" {
  name = "${var.prefix}-concourse-${var.region}"
  ip_cidr_range = "${var.concourse-cidr}"
  network = "${module.terraform-gcp-bosh.bosh-network-link}"
}

resource "null_resource" "bosh-bastion" {
  provisioner "file" {
    source = "${path.module}/files/bosh-bastion/"
    destination = "${var.home}/"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
/*
  provisioner "file" {
    content = "${data.template_file.concourse-properties.rendered}"
    destination = "${var.home}/concourse.properties"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
*/
}

resource "google_compute_global_address" "concourse-web" {
  name = "${var.prefix}-concourse-web"
}

resource "google_compute_firewall" "concourse-web-hc" {
  name          = "${var.prefix}-concourse-web-hc"
  network       = "${var.network}"
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16", "209.85.152.0/22", "209.85.204.0/22"]
  target_tags   = ["concourse-web"]

  allow {
    protocol = "tcp"
    ports    = ["${var.concourse-web-port}"]
  }
}

resource "google_compute_instance_group" "concourse-web-z1" {
  name = "${var.prefix}-concourse-web-z1"
  zone = "${lookup(var.region_params["${var.region}"],"zone1")}"
  named_port {
    name = "http"
    port = "8080"
  }
}

resource "google_compute_instance_group" "concourse-web-z2" {
  name = "${var.prefix}-concourse-web-z2"
  zone = "${lookup(var.region_params["${var.region}"],"zone2")}"
  named_port {
    name = "http"
    port = "8080"
  }
}

resource "google_compute_instance_group" "concourse-web-z3" {
  name = "${var.prefix}-concourse-web-z3"
  zone = "${lookup(var.region_params["${var.region}"],"zone3")}"
  named_port {
    name = "http"
    port = "8080"
  }
}

resource "google_compute_http_health_check" "concourse-web" {
  name         = "${var.prefix}-concourse-web"
  request_path = "/"
  port         = "${var.concourse-web-port}"
}

resource "google_compute_target_http_proxy" "concourse-web" {
  name        = "${var.prefix}-concourse-web"
  url_map     = "${google_compute_url_map.concourse-web.self_link}"
}

resource "google_compute_global_forwarding_rule" "concourse-web" {
  name        = "${var.prefix}-concourse-web"
  target      = "${google_compute_target_http_proxy.concourse-web.self_link}"
  port_range  = "${var.concourse-web-port}"
  ip_protocol = "TCP"
  ip_address  = "${google_compute_address.concourse-web.address}"
}

resource "google_compute_target_http_proxy" "concourse-web" {
  name = "${var.prefix}-concourse-web"
  url_map = "${google_compute_url_map.concourse-web.self_link}"
}

resource "google_compute_url_map" "concourse-web" {
  name = "${var.prefix}-concourse-web"
  default_service = "${google_compute_backend_service.concourse-web.self_link}"
}

resource "google_compute_backend_service" "concourse-web" {
  name        = "concourse-web"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = ["${google_compute_http_health_check.concourse-web.self_link}"]
  backend = [
    { group = "${google_compute_instance_group.concourse-web-z1.self_link}" },
    { group = "${google_compute_instance_group.concourse-web-z2.self_link}" },
    { group = "${google_compute_instance_group.concourse-web-z3.self_link}" },
  ],
}

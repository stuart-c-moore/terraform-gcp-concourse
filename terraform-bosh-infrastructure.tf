module "terraform-gcp-bosh" {
  source = "github.com/migs/terraform-gcp-bosh"
  project = "${var.project}"
  region = "${var.region}"
  prefix = "${var.prefix}"
  zones = "${var.zones}"
  db-ha = "${var.db-ha}"
  bosh-machine_type = "${var.bosh-machine_type}"
  nat-gateway-machine_type = "${var.nat-gateway-machine_type}"
  service_account_name = "${var.service_account_name}"
  service_account_role = "${var.service_account_role}"
  db-version = "${var.db-version}"
}

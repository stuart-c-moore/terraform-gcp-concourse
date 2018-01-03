module "terraform-gcp-bosh" {
  source = "github.com/migs/terraform-gcp-bosh"
  project = "${var.project}"
  region = "${var.region}"
  prefix = "${var.prefix}"
  zones = "${var.zones}"
  db-ha = "${var.db-ha}
  service_account_name = "${var.service_account_name}"
  service_account_role = "${var.service_account_role}"
}

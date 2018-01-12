module "concourse-db" {
  source = "github.com/migs/terraform-gcp-database"
  project = "${var.project}"
  region = "${var.region}"
  ha = "${var.db-ha}"
  db-instance-name = "bosh"
  db-version = "${var.concourse-db-version}"
  authorized_networks = "${module.terraform-gcp-natgateway.nat-gateway-ips["0"]}"
}

resource "random_string" "concourse-password" {
  length = 16
  special = false
}

resource "google_sql_user" "concourse" {
  name = "bosh"
  instance = "${module.concourse-db.db-instance-name}"
  host = "%" 
  password = "${random_string.concourse-password.result}"
}

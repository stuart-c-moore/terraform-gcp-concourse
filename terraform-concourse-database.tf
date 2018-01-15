module "concourse-db" {
  source = "github.com/migs/terraform-gcp-database"
  project = "${var.project}"
  region = "${var.region}"
  ha = "${var.db-ha}"
  db-version = "${var.concourse-db-version}"
  authorized_networks = "${module.terraform-gcp-bosh.nat-gateway-ips["0"]}"
}

resource "random_string" "concourse-password" {
  length = 16
  special = false
}

resource "google_sql_user" "concourse" {
  name = "concourse"
  instance = "${module.concourse-db.db-instance-name}"
  host = "" # https://github.com/terraform-providers/terraform-provider-google/issues/623
  password = "${random_string.concourse-password.result}"
}

resource "google_sql_database" "concourse_atc_db" {
  name = "atc"
  instance = "${module.concourse-db.db-instance-name}"
  charset = "${lookup(var.database_params["charset"],var.concourse-db-version)}"
  collation = "${lookup(var.database_params["collation"],var.concourse-db-version)}"
}

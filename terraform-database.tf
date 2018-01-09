/*

Current focus is to get it up and running, before worrying about an external DB

resource "google_sql_database" "concourse_db" {
  name = "concourse_db"
  instance = "${module.terraform-gcp-bosh.db-instance-name}"
  charset = "${lookup(var.database_params["charset"],var.db-version)}"
  collation = "${lookup(var.database_params["collation"],var.db-version)}"
}

resource "random_string" "concourse-password" {
  length = 16
  special = false
}

resource "google_sql_user" "concourse" {
  name = "concourse"
  instance = "${module.terraform-gcp-bosh.db-instance-name}"
  host = "%"
  password = "${random_string.concourse-password.result}"
}

*/

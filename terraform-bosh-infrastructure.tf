module "terraform-gcp-bosh" {
  source = "github.com/migs/terraform-gcp-bosh"
  project = "${var.project}"
  region = "${var.region}"
  prefix = "${terraform.workspace}"
  zones = "1"
  db-ha = false
  service_account_name = "automated"
  service_account_role = "roles/owner"
}

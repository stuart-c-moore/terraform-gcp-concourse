data "template_file" "concourse-properties" {
  template = <<EOF
#!/usr/bin/env bash
export BOSH_DB_CONCOURSE_USER=$${concourse-user}
export BOSH_DB_CONCOURSE_PORT=$${concourse-password}
EOF
  vars {
    concourse-user = "${google_sql_user.concourse.name}"
    concourse-password = "${random_string.concourse-password.result
  }
}

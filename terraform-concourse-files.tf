data "template_file" "concourse-properties" {
  template = <<EOF
#!/usr/bin/env bash
export CONCOURSE_AUTH_MAIN_USER=$${concourse-auth-main-user}
export CONCOURSE_AUTH_MAIN_PASS=$${concourse-auth-main-pass}
export CONCOURSE_WEB_INSTANCES=$${concourse-web-instances}
export CONCOURSE_WEB_MACHINE=$${concourse-web-machine_type}
export CONCOURSE_WORKER_INSTANCES=$${concourse-worker-instances}
export CONCOURSE_WORKER_MACHINE=$${concourse-worker-machine_type}
export CONCOURSE_URL=$${concourse-url}
export POSTGRES_HOST=$${postgres-host}
export POSTGRES_PORT=$${postgres-port}
export POSTGRES_USER=$${postgres-username}
export POSTGRES_PASS=$${postgres-password}
EOF
  vars {
    concourse-auth-main-user = "${var.concourse-auth-main-username}"
    concourse-auth-main-pass = "${random_string.concourse-auth-main-password.result}"
    concourse-web-instances = "${var.concourse-web-instances}"
    concourse-worker-instances = "${var.concourse-worker-instances}"
    concourse-web-machine_type = "${var.concourse-web-machine_type}"
    concourse-worker-machine_type = "${var.concourse-worker-machine_type}"
    concourse-url = "${var.concourse-url}"
    postgres-host = "${module.concourse-db.db-instance-ip}"
    postgres-port = "${lookup(var.database_params["port"], var.concourse-db-version)}"
    postgres-username = "${google_sql_user.concourse.name}"
    postgres-password = "${random_string.concourse-password.result}"
  }
}

data "template_file" "concourse-create" {
  template = <<EOF
#!/usr/bin/env bash

eval $(./login.sh)
source ./concourse.properties

if [[ ! -f concourse-creds.yml ]]; then
    gsutil cp gs://$project_id-bosh-state/concourse-creds.yml .
fi

if [[ ! -d concourse-deployment ]]; then
    git clone https://github.com/concourse/concourse-deployment.git
else
    cd concourse-deployment
    git pull
    cd ..
fi

cd concourse-deployment/cluster

bosh deploy -d concourse concourse.yml \
  -l ../versions.yml \
  --vars-store ../../concourse-creds.yml \
  -o ../../concourse-support/google-loadbalancer.yml \
  -o ../../concourse-support/multi-zone.yml \
  -o operations/basic-auth.yml \
  -o operations/scale.yml \
  -o operations/external-postgres.yml \
  --var atc_basic_auth.username=$CONCOURSE_AUTH_MAIN_USER \
  --var atc_basic_auth.password=$CONCOURSE_AUTH_MAIN_PASS \
  --var web_instances=$CONCOURSE_WEB_INSTANCES \
  --var worker_instances=$CONCOURSE_WORKER_INSTANCES \
  --var external_url=$CONCOURSE_URL \
  --var postgres_host=$POSTGRES_HOST \
  --var postgres_port=$POSTGRES_PORT \
  --var postgres_role=$POSTGRES_USER \
  --var postgres_password=$POSTGRES_PASS \
  --var network_name=concourse \
  --var web_vm_type=$CONCOURSE_WEB_MACHINE \
  --var db_vm_type=default \
  --var worker_vm_type=$CONCOURSE_WORKER_MACHINE \
  --var db_persistent_disk_type=10GB \
  --var deployment_name=concourse

cd ../..
gsutil cp concourse-creds.yml  gs://$project_id-bosh-state/concourse-creds.yml

sleep 5 # This is a guess
fly -t ci login -c $CONCOURSE_URL
EOF
}

data "template_file" "concourse-web-lb" {
  template = <<EOF
- type: replace
  path: /instance_groups/name=web/vm_extensions?
  value:
  - $${prefix}-concourse-web-lb
EOF
  vars {
    prefix = "${var.prefix}"
  }
}

data "template_file" "concourse-multizone" {
  template = <<EOF
---
- type: replace
  path: /instance_groups/name=web/azs
  value: [z1,z2,z3]
- type: replace
  path: /instance_groups/name=db/azs
  value: [z1,z2,z3]
- type: replace
  path: /instance_groups/name=worker/azs
  value: [z1,z2,z3]
EOF
}

resource "null_resource" "bosh-bastion" {
  provisioner "file" {
    content = "${data.template_file.concourse-properties.rendered}"
    destination = "${var.home}/concourse.properties"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
  provisioner "file" {
    content = "${data.template_file.concourse-create.rendered}"
    destination = "${var.home}/create-concourse.sh"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
  provisioner "remote-exec" {
    inline = [ 
      "chmod +x ${var.home}/create-concourse.sh",
      "mkdir ${var.home}/concourse-support",
    ]   
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
  provisioner "file" {
    content = "${data.template_file.concourse-multizone.rendered}"
    destination = "${var.home}/concourse-support/multi-zone.yml"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
  provisioner "file" {
    content = "${data.template_file.concourse-web-lb.rendered}"
    destination = "${var.home}/concourse-support/google-loadbalancer.yml"
    connection {
      user = "vagrant"
      host = "${module.terraform-gcp-bosh.bosh-bastion-public-ip}"
      private_key = "${var.ssh-privatekey == "" ? file("${var.home}/.ssh/google_compute_engine") : var.ssh-privatekey}"
    }
  }
}

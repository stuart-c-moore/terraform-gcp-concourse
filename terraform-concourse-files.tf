data "template_file" "concourse-create" {
  template = <<EOF
#!/usr/bin/env bash

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
  -o operations/no-auth.yml \
  -o operations/scale.yml \
  -o operations/external-postgres.yml \
  -o ../../concourse-support/google-loadbalancer.yml \
  --var web_instances=$${concourse-web-instances} \
  --var worker_instances=$${concourse-worker-instances} \
  --var external_url=$${concourse-url} \
  --var postgres_host=$${postgres-host} \
  --var postgres_port=$${postgres-port} \
  --var postgres_role=$${postgres-role} \
  --var postgres_password=$${postgres-password} \
  --var network_name=concourse \
  --var web_vm_type=$${concourse-web-machine_type} \
  --var db_vm_type=default \
  --var worker_vm_type=$${concourse-worker-machine_type} \
  --var db_persistent_disk_type=10GB \
  --var deployment_name=concourse

fly -t ci login -c $${concourse-url}
EOF
  vars {
    concourse-web-instances = "${var.concourse-web-instances}"
    concourse-worker-instances = "${var.concourse-worker-instances}"
    concourse-web-machine_type = "${var.concourse-web-machine_type}"
    concourse-worker-machine_type = "${var.concourse-worker-machine_type}"
    concourse-url = "${var.concourse-url}"
    postgres-host = "${module.concourse-db.db-instance-ip}"
    postgres-port = "${lookup(var.database_params["port"], var.concourse-db-version)}"
    postgres-role = "${google_sql_user.concourse.name}"
    postgres-password = "${random_string.concourse-password.result}"
  }
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

resource "null_resource" "bosh-bastion" {
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
      "chmod +x ${var.home}/create-concourse.sh"
    ]   
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

#!/usr/bin/env bash

bosh alias-env ${project_id} -e 10.0.0.6 --ca-cert <(bosh int director-creds.yml --path /director_ssl/ca)
eval $(./login.sh)

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
  --var external_url=http://concourse.migs.wtf:8080 \
  --var network_name=default \
  --var web_vm_type=default \
  --var db_vm_type=default \
  --var worker_vm_type=default \
  --var db_persistent_disk_type=10GB \
  --var deployment_name=concourse

cd ../..

fly -t ci login -c http://10.10.0.2:8080

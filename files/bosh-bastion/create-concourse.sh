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

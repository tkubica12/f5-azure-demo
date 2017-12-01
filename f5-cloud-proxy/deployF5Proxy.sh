#!/bin/bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
sudo apt-get install -y docker-ce
docker load -i f5-acproxy-1.1.0-build.70.tgz
docker run -d --restart=always --net=host -e retry=true -e publish=true -e proxyName=f5-cloud-proxy -e user=tomas -e passwd=Azure12345678 -it f5/acproxy:1.1.0-build.70
#!/bin/sh
set -e

# Add additional OS packages
packages="aws-cfn-bootstrap awslogs jq nfs-utils docker"

# Exclude Docker and ECS Agent from update
sudo yum -y -x docker\* -x ecs\* update
echo "### Installing extra packages: $packages ###"
sudo yum -y install $packages

# Install confd
sudo curl -L -o /usr/bin/confd https://github.com/kelseyhightower/confd/releases/download/v0.12.0-alpha3/confd-0.12.0-alpha3-linux-amd64
sudo chmod +x /usr/bin/confd
sudo mkdir -p /etc/confd


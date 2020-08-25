#!/usr/bin/env bash

apt-get update -y

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

usermod ubuntu -a -G docker

apt-get install -y python3-pip

pip3 install awscli
bash -c "$(aws ecr get-login --no-include-email --region eu-west-1)"
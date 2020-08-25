#!/usr/bin/env bash

yum update -y
amazon-linux-extras install docker
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user
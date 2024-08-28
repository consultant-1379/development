#!/usr/bin/env bash

eval `ssh-agent -s`
mkdir -p /home/jenkins/.ssh/
cp /root/.ssh/adp/id_rsa /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-add /root/.ssh/id_rsa

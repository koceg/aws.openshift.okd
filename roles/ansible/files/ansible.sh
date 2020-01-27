#!/bin/bash

cat<<EOF

Configure Ansible Host Instance
===============================

EOF

PKG='screen git selinux httpd-tools java-1.8.0-openjdk-headless rh-python36'
OPENSHIFT='https://github.com/openshift/openshift-ansible.git'
RELEASE='release-3.11'
PYTHON='/opt/rh/rh-python36/root/bin/python3'
PYTHON_USR_BIN='/usr/bin/python3'
PYTHON_PIP='/opt/rh/rh-python36/root/bin/pip'
PIP_URL='https://bootstrap.pypa.io/get-pip.py'

for x in {requirements.txt,openshift.gen,registry.gen,pre_cluster_config.sh,aws}
do
  scp -i aws $x centos@$1:/home/centos/
done

ssh -t -i aws centos@$1 "sudo yum update -y \
  && sudo yum install -y centos-release-scl \
  && curl $PIP_URL -o get-pip.py \
  && sudo yum install $PKG -y \
  && sudo $PYTHON get-pip.py \
  && sudo $PYTHON_PIP install -r requirements.txt \
  && git clone $OPENSHIFT --depth 1 --branch $RELEASE \
  && sudo ln -s $PYTHON $PYTHON_USR_BIN \
  && chmod +x pre_cluster_config.sh \
  && ./pre_cluster_config.sh"

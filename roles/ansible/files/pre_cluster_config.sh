#!/bin/bash

cat<<EOF

Prepare the hosts 
before starting ansible-playbooks.
===================================

EOF

for x in $(cat *\.gen | grep -E "^[0-9]" |cut -f1 -d" "|sort|uniq)
do 
  ssh -i aws centos@$x \
    "sudo cp ~/.ssh/auth* /root/.ssh/ \
    && sudo chown -R root:root /root/.ssh/ \
    && sudo yum -y install NetworkManager \
    && sudo systemctl enable NetworkManager \
    && sudo systemctl start NetworkManager"
done

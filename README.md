### Ansible AWS OpenShift/OKD v3.11 Cluster Install 

The purpose of this repo is to provide a straightforward way of installing openshift/OKD v3.11 cluster in a simple way once we provide the desired number of nodes.

### Requirements

AWS subscription is required,more precisely ec2 access_key and secret key.   
When you have you aws authentication credentials, a file with the name **.boto** needs to be present inside your home directory

```bash
cat << EOF > $HOME/.boto
[Credentials]
aws_access_key_id = YOURACCESSKEY
aws_secret_access_key = YOURSECRETKEY
EOF
```
also you'd need a minimal **ANSIBLE** version that works with boto to interact with 
the AWS services for environment initialization.

### AWS Infrastructure Preperation
one you set that up these are the commands that need to be run
```bash
cd aws.openshift.okd
#generate or copy a pre-generated RSA key inside '$PWD/aws'
#NOTE change the value of `sshPublicKey` inside 'roles/vpc/defaults/main.yml' to reflect your public ssh key
ansible-playbook openshift_cluster_setup.yml  # you'll be prompted for the number of nodes

export ANSIBLE_HOST_KEY_CHECKING=False # we use this not to be prompted for every hosts ssh key accept dialogue 

ansible-playbook --private-key $PWD/aws -i $PWD/roles/ansible/files/public_nodes.gen -u centos cluster_preconfigure.yml
```

### OpenShift Install

Now we can login to our ansible host inside our VPC network and install OKD(OpenShift)

```bash
ssh -i aws/aws centos@(PUBLIC IP/HOSTNAME OF ANSIBLE HOST)
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook --private-key=aws -i openshift.gen openshift-ansible/playbooks/prerequisites.yml
ansible-playbook --private-key=aws -i openshift.gen openshift-ansible/playbooks/deploy_cluster.yml
```
this will install our main openshift cluster. If you want to deploy independent registry node you need to change `openshift.gen` file to `registry.gen` file if registry node is present.


### Final notes
After all of the steps above are executed we should have a running cluster.
We are doing it this way because we use the private IPs from the nodes so we can 
avoid common public/private resolution problems during installation.
We can keep our ansible node that we used during the installation as a oc cmd workstation,nfs server
or delete it.

To access our cluster web GUI we should add the public ip from our master node inside hosts file for resolving

(master public IP)  (master private dns/hostname instance)

**https://(master private dns hostname):8443**

### Infrastructure Management

#### *NOTE: If left "AS IS" this cluster will become very expensive very fast*
to keep costs at minimum run
```bash
cd aws.openshift.okd
ansible-playbook openshift_node_management.yml #(start/stop/delete)
```

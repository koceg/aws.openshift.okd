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
the AWS services for environment initialisation.

If help is needed take a look at **ansible.sh** script

### Infrastructure Install
One you set that up these are the commands that need to be run in the following order

```bash
cd aws.openshift.okd
#generate or copy a pre-generated RSA key inside '$PWD/roles/ansible/files'
ansible-playbook openshift_cluster_setup.yml
cd $PWD/roles/ansible/files
./ansible.sh (PUBLIC IP OF ANSIBLE HOST) 
```

this host is a **t2.micro** instance inside our vpc network with tag name **ansible** 

Once that last command is finished our infrastructure should be prepared.

### OpenShift Install

while we are still inside ** _$PWD/roles/ansible/files_** :

```bash
ssh -i aws/aws centos@(PUBLIC IP/HOSTNAME OF ANSIBLE HOST)
PATH=$PATH:/opt/rh/rh-python36/root/bin # ansible executable scripts are installed under this path
ansible-playbook --private-key=aws -i openshift.gen openshift-ansible/playbooks/prerequisites.yml
ansible-playbook --private-key=aws -i openshift.gen openshift-ansible/playbooks/deploy_cluster.yml
```
this will install our main openshift cluster. If you want to deploy independent registry node you need to change openshift.gen file to registry.gen file if regitry node is present.

### Final notes
After all of the steps above are executed we should have a runing cluster.
We are doing it this way because we use the private IPs from the nodes so we can 
avoid common public/private resolution problems during installation.
We can keep our ansible node that we used during the installation as a cmd workstation/nfs test server
or delete it.

To access our cluster web GUI we should add the public ip from our master node inside hosts file for resolving

(master public IP)  (master private dns/hostname instance) 
because we get a redirect to the private ip and we'll get "host not found" 

**https://(MASTER NODE PUBLIC IP):8443**

### Infrastructure Management

#### *NOTE: If left "AS IS" this cluster will become very expensive very fast*
to keep costs at minimum run
```bash
cd aws.openshift.okd
ansible-playbook openshift_node_management.yml #(start/stop/delete)
```
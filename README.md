### Ansible AWS OpenShift/OKD v4.x Cluster Installation

The purpose of this repo is to provide a straightforward way of installing openshift/OKD v4.x cluster in a simple way where we provision our infrastructure the way we see fit.

### Requirements

- AWS **access key ID / secret access key** required with the following **IAM** permissions:
  - AmazonEC2FullAccess
  - AmazonRoute53FullAccess 
  - AmazonS3FullAccess
    - **OR** when s3 bucket already exists only the below s3 permissions
    - "s3:PutObject"
    - "s3:GetObject"
    - "s3:DeleteObject"
    - "s3:PutObjectAcl"

- Domain name that is managed by **route53** (can be any cheap domain **name is not important** )<br>

  - *NOTE: This should be possible to accomplish without domain name purchase, **IF** one can set up a host or provide other way of resolving the domain names that are going to be used to setup this cluster internally and externally.*
- ***oc*** cli program that is compatible wit the version of OpenShift/OKD that we are trying to install

  - [oc latest version](https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz)
  
- ***openshift-install*** cli program that comes with the version of OpenShift/OKD that we are trying to install
  >`oc adm release extract --tools registry.svc.ci.openshift.org/origin/release:XXXXXX`<br>
  
  > ( this is a bit of a catch we need the latest oc in order to get the install program that is going to generate the config files used for the installation )
  
- Ansible version that supports the modules used to accomplish our end goal. In my tests I used version 2.9.5 at time of writing

  - [ansibleAWS](https://github.com/koceg/ansibleAWS) Docker Image that meets the prerequisites for Ansible,AWS and Openshift/OKD
- ***SSH Key*** that should be pregenerated so we can login to our nodes later if needed

### Installation
Once our requirements are met 
```bash
cd aws.openshift.okd


#NOTE change the value of `sshPublicKey` inside 'roles/config/defaults/main.yml' to reflect your public ssh key

#NOTE on first run don't add worker nodes
> ansible-playbook openshift.yml  # you'll be prompted for the values that are relevant to the new cluster
```

Depending on the speed of execution of our playbook by the time it is done our master nodes should be up and running 

to confirm we run the following commands

```
> openshift-install wait-for bootstrap-complete --dir=ignition
# we should get a message informing us that it's safe to remove our bootstrap node

export KUBECONFIG=$PWD/ignition/auth/kubeconfig

# testing to see if everithing is ok

> oc get nodes # should return our master nodes
> oc get csr # to see if we have pendig certificates
```

At this point all that is left to do is remove the bootstrap node and add the desired amount of worker nodes that should be part of our cluster.<br><br>
To do that just re-run our ansible command from above providing the worker nodes count <br><br>
Once our playbook is finished provisioning our worker nodes we should run:<br>
```
> oc get nodes # in a few minutes our worker nodes should appear alongside our master nodes
> oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs oc adm certificate approve
# approving the new nodes certificates

> openshift-install wait-for install-complete --dir=ignition
# should inform us on successful installation echoing back login url,username and password
```
[openshift baremetal installation documentation](https://docs.openshift.com/container-platform/4.3/installing/installing_bare_metal/installing-bare-metal.html#installation-installing-bare-metal_installing-bare-metal) should provide extra information if something is left out of the process presented here


### Pitfalls 
The way CoreOS is provisioned can be a bit of a challenge to troubleshoot if we have a running instance or if that instance is stuck booting.<br><br>
In our AWS console under EC2 instances while we provision our cluster nodes we should
```
'Instance settings'->'Get Instance Screenshot'
# observe the sequence of events that are happening
```
if we get a stuck sequence or if we don't see a login prompt with a short description of the ssh generated keys could mean that our ***ignition data*** provided to our instance is in the wrong format.<br>
To corect that we need to try and generate new ***ignition file*** that would be used for our bootstrap machine
```
cat<<EOF>ignition.yaml
variant: fcos
version: 1.0.0
ignition:
  config:
    replace:
      source: https://{{aws_base_s3_url}}/{{ domainName }}/bootstrap.ign
EOF

docker run -i --rm quay.io/coreos/fcct:release --pretty --strict < ignition.yaml > bootstrap.ign
docker run --rm -i quay.io/coreos/ignition-validate:v2.1.1 - < bootstrap.ign

mv bootstrap.ign  aws.openshift.okd/roles/nodes/files/bootstrap.ign
```
Reason is the accepted version number that we've used previously if not compatible with the version number that our image is expecting and base on the mismatch our initial ignition file is invalidated or the structure of the provided initial ignition file has changed.<br><br>
[Ignition File](https://docs.fedoraproject.org/en-US/fedora-coreos/fcct-config/) For more information and future changes
### Infrastructure Management

#### *NOTE: If left "AS IS" this cluster will become very expensive very fast*
to keep costs at minimum run
```bash
cd aws.openshift.okd
ansible-playbook openshift_nodes.yml #(start/stop/delete)
```

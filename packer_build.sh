#! /bin/bash
set -e

packer_template="$1"
var_file="$2"

### Start the Build. ###
echo "Starting the build with Packer template: $packer_template"
packer build -force \
-var-file="$var_file" \
-var-file=./packer/vars/common.pkrvars.hcl \
-var-file=./packer/vars/build.pkrvars.hcl \
-var-file=./packer/vars/proxmox.pkrvars.hcl \
-var-file=./packer/vars/ansible.pkrvars.hcl \
"$packer_template"

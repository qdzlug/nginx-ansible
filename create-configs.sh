#!/bin/bash
#
# Simple script to build out connection information to be used as part of this
# demo setup. Is not production ready, should not be used in production, etc.
#

# Set the base directory to the current script's location.
BASEDIR=$(pwd)

# Define the path to the Terraform and jq binaries.
TERRAFORM=$(which terraform)
TERRAFORMARGS="output --json"
JQ=$(which jq)

# Define paths to the necessary files, now relative to the main directory.
SSHKEY="$BASEDIR/files/nginx.pem"
SSHCONFIG="$BASEDIR/files/nginx.ssh.config"
ANSIBLEHOSTS="$BASEDIR/files/nginx.ansible.hosts"

# Ensure the files directory exists (though it should, given your structure).
mkdir -p "$BASEDIR/files"

# Change directory to where the Terraform configuration is located.
cd "$BASEDIR/terraform" || exit

## Parse out the IP addresses we need using Terraform and jq.
cd $BASEDIR/terraform
PUBLICIP=$($TERRAFORM $TERRAFORMARGS | $JQ '.nginx_public_ip_address.value')
NGINX=$($TERRAFORM $TERRAFORMARGS | $JQ '.nginx_address.value')

# Extract the SSH key, directing it to the appropriate file.
$TERRAFORM show -json | $JQ -r \
'.values.root_module.resources[].values | select(.private_key_pem) | .private_key_pem' > $SSHKEY
chmod 600 $SSHKEY
echo "Private key written to $SSHKEY"
cd $BASEDIR

# Write out the SSH configuration file.
echo "Host nginx" > $SSHCONFIG
echo "    User azureuser" >> $SSHCONFIG
echo "    HostName $PUBLICIP" >> $SSHCONFIG
echo "    StrictHostKeyChecking no" >> $SSHCONFIG
echo "    IdentityFile $SSHKEY" >> $SSHCONFIG
echo "" >> $SSHCONFIG

echo "SSH configuration written"

# Build Ansible configuration.
echo "[all:vars]" > $ANSIBLEHOSTS
echo "ansible_user=azureuser" >> $ANSIBLEHOSTS
echo "ansible_become=yes" >> $ANSIBLEHOSTS
echo "ansible_become_method=sudo" >> $ANSIBLEHOSTS
echo "ansible_python_interpreter=/usr/bin/python3" >> $ANSIBLEHOSTS
echo "ansible_ssh_common_args='-F $SSHCONFIG'" >> $ANSIBLEHOSTS
echo "" >> $ANSIBLEHOSTS
echo "[nginx_main]" >> $ANSIBLEHOSTS
echo "nginx" >> $ANSIBLEHOSTS
echo "" >> $ANSIBLEHOSTS

echo "Configuration complete. Instructions for use:"
echo
echo "To SSH into the nginx server, add the private key to your SSH agent:"
echo "ssh-add $SSHKEY"
echo
echo "Then, use SSH with the config file:"
echo "ssh -F $SSHCONFIG nginx"
echo
echo "To test the Ansible inventory, run:"
echo "ansible-playbook -i $ANSIBLEHOSTS $BASEDIR/ansible/ansible-ping.yaml"
echo
echo "Ensure there are no errors for proper configuration."
echo
echo "To install NGINX with ansible, run:"
echo "ansible-playbook -i $ANSIBLEHOSTS $BASEDIR/ansible/deploy-oss.yaml"
echo
echo "To uninstall NGINX with ansible, run:"
echo "ansible-playbook -i $ANSIBLEHOSTS $BASEDIR/ansible/uninstall-oss.yaml"
echo
echo "To upgrade NGINX with ansible, run:"
echo "ansible-playbook -i $ANSIBLEHOSTS $BASEDIR/ansible/upgrade-oss.yaml"

# No need to navigate back, as we're done executing commands.

#!/bin/bash

# Check if Ansible is installed by trying to get its version.
if ! ansible --version > /dev/null 2>&1; then
    echo "Ansible is not installed. Please install Ansible before continuing."
    exit 1
fi

# Install the NGINX ansible collection dependencies.
echo "Installing NGINX Ansible collection dependencies..."
ansible-galaxy collection install ansible.posix community.crypto community.general

# Install the NGINX ansible collection.
echo "Installing NGINX Ansible collection..."
ansible-galaxy collection install nginxinc.nginx_core

# Install the NGINX role.
echo "Installing NGINX role..."
ansible-galaxy role install nginxinc.nginx

echo "Installation complete."

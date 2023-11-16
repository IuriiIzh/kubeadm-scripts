#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euo pipefail
echo "Configuration for master node starts:"

# If you need public access to API server using the servers Public IP adress, change PUBLIC_IP_ACCESS to true.

PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR=10.85.0.0/16
SVC_CIDR=10.86.0.0/16



# Configure firewall
if [[ $(sudo firewall-cmd --list-all-zones| grep -q 000-kubernetes) ]]; 
  then
    echo "firewall zone already created"
  else
    sudo firewall-cmd --permanent --new-zone 000-kubernetes
fi
sudo firewall-cmd --permanent --set-target=ACCEPT --zone=000-kubernetes
sudo firewall-cmd --permanent --add-masquerade --zone=000-kubernetes
sudo firewall-cmd --permanent --zone=000-kubernetes --add-source=192.168.0.0/16
sudo firewall-cmd --permanent --zone=000-kubernetes --add-source="$POD_CIDR" --add-source="$SVC_CIDR"
sudo firewall-cmd --reload

# Pull required images

sudo kubeadm config images pull

# Initialize kubeadm based on PUBLIC_IP_ACCESS

if [[ "$PUBLIC_IP_ACCESS" == "false" ]]; then
    
    MASTER_PRIVATE_IP=$(ip addr show $INTERFACE | awk '/inet / {print $2}' | cut -d/ -f1)
    sudo kubeadm init --apiserver-advertise-address="$MASTER_PRIVATE_IP" --apiserver-cert-extra-sans="$MASTER_PRIVATE_IP" --pod-network-cidr="$POD_CIDR" --service-cidr="$SVC_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

elif [[ "$PUBLIC_IP_ACCESS" == "true" ]]; then

    MASTER_PUBLIC_IP=$(curl ifconfig.me && echo "")
    sudo kubeadm init --control-plane-endpoint="$MASTER_PUBLIC_IP" --apiserver-cert-extra-sans="$MASTER_PUBLIC_IP" --pod-network-cidr="$POD_CIDR" --node-name "$NODENAME" --ignore-preflight-errors Swap

else
    echo "Error: MASTER_PUBLIC_IP has an invalid value: $PUBLIC_IP_ACCESS"
    exit 1
fi

# Configure kubeconfig

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Install Claico Network Plugin Network 

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml -O

kubectl create -f custom-resources.yaml

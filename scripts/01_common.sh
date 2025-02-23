#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -eo pipefail

if [[ $1 != master ]] && [[ $1 != worker ]] ;
  then
  echo "Set up Kubernetes master and worker nodes"
  echo "usage:"
  echo " $0" 'master' ' or ' " $0" 'worker IP_MASTER_VM_WITH_PORT TOKEN HASH'
  exit
fi

echo "You are configuring $1 node"

# Variable Declaration

KUBERNETES_VERSION="1.28.1-00"
PUBLIC_IP_ACCESS="false"
NODENAME=$(hostname -s)
POD_CIDR=10.85.0.0/16
SVC_CIDR=10.86.0.0/16

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


# Install CRI-O Runtime

OS="xUbuntu_22.04"

VERSION="1.28"
INTERFACE="ens18"

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv6.conf.all.forwarding=1
EOF

sudo sysctl --system

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

sudo apt-get update
sudo apt-get install runc cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl enable crio --now

echo "CRI runtime installed susccessfully"

# Install kubelet, kubectl and Kubeadm

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install --allow-downgrades -y kubelet="$KUBERNETES_VERSION" kubectl="$KUBERNETES_VERSION" kubeadm="$KUBERNETES_VERSION"
sudo apt-get update -y
sudo apt-get install -y jq




# Configure firewall
#KUBZONE_EXIST=$(sudo firewall-cmd --list-all-zones| grep  000-kubernetes)
#if [[ -n $KUBZONE_EXIST ]]; 
#  then
#    echo "firewall zone already created"
#  else
#    sudo firewall-cmd --permanent --new-zone 000-kubernetes
#fi
#sudo firewall-cmd --permanent --set-target=ACCEPT --zone=000-kubernetes
#sudo firewall-cmd --permanent --add-masquerade --zone=000-kubernetes
#sudo firewall-cmd --permanent --zone=000-kubernetes --add-source=192.168.0.0/16
#sudo firewall-cmd --permanent --zone=000-kubernetes --add-source="$POD_CIDR" --add-source="$SVC_CIDR"



#sudo firewall-cmd --reload


local_ip="$(ip --json addr show $INTERFACE | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
#sudo cat > /etc/default/kubelet << EOF
#KUBELET_EXTRA_ARGS=--node-ip=$local_ip
#EOF
sudo tee /etc/default/kubelet >/dev/null <<EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

if [[ $1 = master ]] ;
  then
  . ./master.sh
else
    sudo kubeadm join $2 --token $3 --discovery-token-ca-cert-hash $4
    echo "Worker node was added to cluster successfully"
fi



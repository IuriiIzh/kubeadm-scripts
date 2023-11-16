#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -eo pipefail

sudo kubeadm reset -f

sudo rm -rf /etc/kubernetes/
sudo rm -rf /etc/cni/
sudo rm -rf /etc/crio/
sudo rm -rf /etc/containers/

sudo rm -rf /opt/kubernetes/
sudo rm -rf /opt/cni/

sudo crictl ps -q | xargs -n 1 crictl stop
sudo crictl ps -q | xargs -n 1 crictl rm
sudo apt-get remove cri-o cri-o-runc -y

sudo firewall-cmd --permanent --delete-zone 000-kubernetes

sudo systemctl reboot
#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -eo pipefail

sudo kubeadm reset

sudo rm -rf /etc/kubernetes/

sudo rm -rf /opt/kubernetes/
sudo rm -rf /etc/cni/
sudo firewall-cmd --permanent --delete-zone 000-kubernetes
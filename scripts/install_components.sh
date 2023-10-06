#!/bin/bash
#


set -euo pipefail

# Install calico networking plugin.
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml




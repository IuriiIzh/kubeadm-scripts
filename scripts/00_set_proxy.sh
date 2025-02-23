#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euo pipefail
echo "Proxy Configurations will be added to /etc/environment and /etc/apt/apt.conf.d/95proxies files"

cat <<EOF | sudo tee /etc/environment
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin"
http_proxy="http://192.168.0.218:8080/"
https_proxy="http://192.168.0.218:8080/"
ftp_proxy="http://192.168.0.218:8080/"
no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com,192.168.0.0/16,10.85.0.0/16,10.86.0.0/16"
HTTP_PROXY="http://192.168.0.218:8080/"
HTTPS_PROXY="http://192.168.0.218:8080/"
FTP_PROXY="http://192.168.0.218:8080/"
NO_PROXY="localhost,127.0.0.1,localaddress,.localdomain.com,192.168.0.0/16,10.85.0.0/16,10.86.0.0/16"
EOF

cat <<EOF | sudo tee /etc/apt/apt.conf.d/95proxies
Acquire::http::proxy "http://192.168.0.218:8080/";
Acquire::ftp::proxy "http://192.168.0.218:8080/";
Acquire::https::proxy "http://192.168.0.218:8080/";
EOF

sudo systemctl reboot

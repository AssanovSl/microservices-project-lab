#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Docker installation.. ==="

sudo apt update -qq 2>/dev/null
sudo apt upgrade -y -qq 2>/dev/null

sudo apt install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release 2>/dev/null

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo usermod -aG docker vagrant

docker -v
docker compose version
echo "=== Docker instaled.. ==="

sudo systemctl enable docker
sudo systemctl start docker

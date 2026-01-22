#!/bin/bash

set -e

MANAGER_IP="192.168.56.10"

if [[ $(hostname) == "manager01" ]]; then

    sudo docker swarm init --advertise-addr $MANAGER_IP
    sudo docker swarm join-token worker -q > /vagrant/worker_token.txt

    echo "✅ Swarm initialized. Token saved."


else
    # проверка присутсвия токена
    if [ ! -f /vagrant/worker_token.txt ]; then
        echo "❌ Error: Worker token file not found!"
        echo "   Make sure manager01 completed successfully first."
        exit 1
    fi
    WORKER_TOKEN=$(cat /vagrant/worker_token.txt)
    sudo docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
    echo "✅ Worker $(hostname) joined"
fi
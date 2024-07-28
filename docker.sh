#!/bin/bash
clear

echo "Install Docker"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo docker --version

echo "Install Docker Compose"

sudo wget https://github.com/docker/compose/releases/download/v2.27.0/docker-compose-linux-x86_64 -O /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
sudo docker-compose --version

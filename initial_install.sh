#!/bin/bash -e

sudo apt update
sudo apt full-upgrade -y

# https://eternalterminal.dev/download/
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:jgmath2000/et
sudo apt update
sudo apt install -y et tmux wget

# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
sudo groupadd -f docker
sudo usermod -aG docker $USER
newgrp docker

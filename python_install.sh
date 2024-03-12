#! /bin/bash -e

sudo apt update
sudo apt dist-upgrade -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip python3.11 python3.11-dev wget

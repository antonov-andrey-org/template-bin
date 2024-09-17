#! /bin/bash -e

sudo apt update
sudo apt dist-upgrade -y
sudo apt install -y default-libmysqlclient-dev build-essential pkg-config mysql-client python3-pip python3.12 python3.12-dev software-properties-common wget

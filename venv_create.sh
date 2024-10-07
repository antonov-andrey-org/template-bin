#! /bin/bash -e

sudo apt install python3-virtualenv
if [ -d "venv" ];
then
  sudo rm -rf venv
fi
sudo mkdir venv
sudo chown -R $USER:$USER ./
python3 -m virtualenv venv
source venv/bin/activate
pip install -U pip setuptools wheel
if [ -f "requirements.txt" ];
then
  pip install -r requirements.txt
fi

mkdir -p log

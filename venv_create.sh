#! /bin/bash -e

python3.11 -m pip install virtualenv
if [ -d "venv" ];
then
  sudo rm -rf venv
fi
sudo mkdir venv
sudo chown -R $USER:$USER ./
python3.11 -m virtualenv venv
source venv/bin/activate
pip install -U pip setuptools wheel
pip install -r requirements.txt

mkdir -p log
wget "https://storage.yandexcloud.net/cloud-certs/CA.pem" -O mysql.crt
chmod 0600 mysql.crt

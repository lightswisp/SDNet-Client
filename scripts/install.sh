#!/usr/bin/bash

echo "Installation script is starting..."

sudo apt update

sudo apt install -y git build-essential libgtk-3-0 libwebkit2gtk-4.0-37

curl -fsSL https://crystal-lang.org/install.sh | sudo bash

git clone https://github.com/lightswisp/SDNet-Client.git sdnet-client

cd sdnet-client

shards install

crystal build --release main.cr -o sdnet

sudo mv sdnet /usr/bin

wget https://github.com/lightswisp/SDNet-Client/releases/download/Release-linux/sdnet.deb

sudo dpkg -i sdnet.deb

cd ..

echo "Cleaning up..."

rm -rf sdnet-client

echo "Done!" 



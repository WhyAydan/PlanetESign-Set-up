#!/bin/sh

# This script should set up all of the dependencies needed for the PlanetESign digital signage players on Ubunutu

#Written by KMA and Aydan Abrahams

echo "Running as "$(whoami)

if [ $(whoami) != "root" ];
then
    echo "Please run this command with sudo"
    exit 3

fi

cd ..

#Install OpenSSH
echo "Installing OpenSSH Server"
apt install openssh-server
wait

#Remove Firefox and replace with Chromium
echo "Replacing Firefox with Chromium"
apt remove Firefox
wait
apt install chromium-browser
wait

# Install node.js
echo "Installing node.js and it's requirements"
apt install curl wget -y
wait
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
wait
apt install nodejs -y
wait

# Install the ESign client
echo "Installing ESign client and it's requirements"
apt install npm openjdk-8-jre -y
wait
npm install -g node-gyp
wait

# 'Disable' Chromium updates
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check

# Reboot to start esign
#reboot

echo -e "\e[1;31m **** Please run the following command to install the ESign client! Make sure you are not running as root **** \e[0m"
echo -e "\e[1;31m **** wget -qO- https://planetestream.co.uk/files/install_esign.sh | bash - **** \e[0m
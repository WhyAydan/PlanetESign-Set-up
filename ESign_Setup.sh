#!/bin/bash

# This script should set up all of the dependencies needed for the PlanetESign digital signage players on Debian/Raspian

echo "Running as "$(whoami)

if [ $(whoami) != "root" ];
then
    echo "Please run with sudo!"
    exit 3

fi


# Install node.js
echo "Installing node.js and it's requirements"
apt install curl -y
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
apt install nodejs -y

# Install the ESign client
echo "Installing ESign client and it's requirements"
apt install wget -y
apt install npm 
apt remove firefox
apt install chromium-browser
apt install openjdk-8-jre
npm install -g node-gyp
cd ~/
su -c "wget -vO- https://planetestream.co.uk/files/install_esign.sh | bash -" esign

# Add reboot time to crontab
echo "Adding Reboot Cronjob"
crontab -l > mycron
# Cron format is Day, Hour, Day of Month, Month, Day of Week, command
echo "5 8 * * 1-5 reboot"
crontab mycron
rm mycron

# 'Disable' Chromium updates
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check



# Reboot to start esign
#reboot
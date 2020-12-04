#!/bin/sh

# This script should set up all of the dependencies needed for the PlanetESign digital signage players on Debian/Raspian

#Written by KMA

echo "Running as "$(whoami)

if [ $(whoami) != "root" ];
then
    echo "Please run with sudo!"
    exit 3

fi

nodeDeps = "curl"
esignDeps = "wget npm chromium-browser openjdk-8-jre"

# Install node.js
echo "Installing node.js and it's requirements"
apt install $nodeDeps -y
wait
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
wait
apt install nodejs -y

# Install the ESign client
echo "Installing ESign client and it's requirements"
apt install $esignDeps -y
wait
npm install -g node-gyp
wait
cd ~/

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
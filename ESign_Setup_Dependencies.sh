#!/bin/sh

# This script should set up all of the dependencies needed for the PlanetESign digital signage players on Debian/Raspian

#Written by KMA

echo "Running as "$(whoami)

if [ $(whoami) != "root" ];
then
    echo "Please run with sudo!"
    exit 3

fi

#Install OpenSSH
echo "Installing OpenSSH"
apt install openssh-server
wait

#Remove Firefox and replace with Chromium
echo "Replacing browser with Chromium"
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
cd ~/

# Add reboot time to crontab
#echo "Adding Reboot Cronjob"
#crontab -l > mycron
# Cron format is Day, Hour, Day of Month, Month, Day of Week, command
#echo "5 8 * * 1-5 reboot"
#crontab mycron
#rm mycron
wait

# 'Disable' Chromium updates
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check

# Reboot to start esign
#reboot
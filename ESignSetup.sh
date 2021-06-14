#!/bin/sh

# This script should set up all of the dependencies and install PlanetESign along with SupportMe

#Written by Kyle and Aydan

echo "Running as "$(whoami)

if [ $(whoami) != "root" ];
then
    echo "Please run this command with sudo"
    exit 3

fi

#Install OpenSSH
echo "Installing OpenSSH Server"
apt install openssh-server
wait

#Remove Firefox and replace with Chromium
echo "Replacing Firefox with Chromium"
apt remove firefox -y
wait
apt install chromium-browser
wait

# Install node.js
echo "Installing node.js and it's requirements"
apt install curl wget -y
wait
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -
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
echo "Disbaling Chromium auto updates - if this fails then its no biggy"
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check

# Reboot to start esign
#reboot

#Install SupportMe
echo "Installing CMAT SupportMe"
chmod +x CMATSupportMe.ClientSetup.deb
dpkg -i CMATSupportMe.ClientSetup.deb

echo -e "\e[1;31m **** Please run the following command to install the ESign client if the auto install fails! **** \e[0m"
echo -e "\e[1;31m wget -qO- https://planetestream.co.uk/files/install_esign.sh | bash - \e[0m"
echo "Continuing in 5 seconds"

sleep 5

# This bit doesn't quite work properly :P
wget -qO- https://planetestream.co.uk/files/install_esign.sh > install_esign.sh
wait
sudo -u esign sh ./install_esign.sh


echo "Do you wish to restart?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) reboot;;
        No ) exit;;
    esac
done

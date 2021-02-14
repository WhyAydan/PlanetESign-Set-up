#!/bin/sh

# This script should set up all of the dependencies needed for the PlanetESign digital signage players on Ubunutu

#Written by KMA and Aydan Abrahams

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

# Install VNC Server
echo "Installing VNC Server"
autovncDeps = " git psmisc"
apt install tigervnc-scraping-server
wait
vncpasswd
wait
apt install $autovncDeps
wait
git clone https://github.com/sebestyenistvan/runvncserver
wait
cp ~/runvncserver/startvnc ~
chmod +x ~/startvnc
./startvnc start
#cd ~/

# Add reboot time to crontab
#echo "Adding Reboot Cronjob"
#crontab -l > mycron
# Cron format is Day, Hour, Day of Month, Month, Day of Week, command
#echo "5 8 * * 1-5 reboot"
#crontab mycron
#rm mycron
#wait

# 'Disable' Chromium updates
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check

# Reboot to start esign
#reboot

#echo -e "\e[1;31m **** Please run the following command to install the ESign client! **** \e[0m"
#echo -e "\e[1;31m wget -qO- https://planetestream.co.uk/files/install_esign.sh | bash - \e[0m"
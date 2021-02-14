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

echo "Updating and installing dependencies"
sudo apt-get update 1>/dev/null
sudo apt-get dist-upgrade -y 1>/dev/null
sudo apt-get install default-jdk unclutter chromium-browser unzip -y 1>/dev/null
sudo apt-get remove gnome-screensaver -y 1>/dev/null

# In some setups HTTPS sites will not load in Java without this being setup
echo "Updating Java SSL settings"
printf '\xfe\xed\xfe\xed\x00\x00\x00\x02\x00\x00\x00\x00\xe2\x68\x6e\x45\xfb\x43\xdf\xa4\xd9\x92\xdd\x41\xce\xb6\xb2\x1c\x63\x30\xd7\x92' | sudo tee /etc/ssl/certs/java/cacerts 1>/dev/null
sudo /var/lib/dpkg/info/ca-certificates-java.postinst configure 1>/dev/null

echo 'Attempting to disable screensaver, display lock, and auto dim options'
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false

# Keyring for saving passwords usually will unlock, when a user is set to automatically login this is not automatically done.
# This disables the keyring operation so it does not show for each load
echo 'Disabling Gnome Keyring'
sudo chmod -x $(type -p gnome-keyring-daemon)

# The HDMI audio can have issues with certain versions of the Intel Compute Stick,
# this fix is explained in http://linuxiumcomau.blogspot.com/2018/03/fixing-broken-hdmi-audio-again.html?
prod=$(cat /sys/class/dmi/id/product_name)
if [[ $prod == 'STK1A32SC' ]] || [[ $prod == 'STK1AW32SC' ]]; then
	echo "Intel Compute Stick detected! Applying audio patch"
	if grep -Rq "Linuxium" /etc/pulse/default.pa; then
		echo "Compute Stick audio fix already set"
	else
		sudo sed -i '/module-detect/ {n;a\
		### Linuxium fix for HDMI audio on Intel Compute Stick products STK1A32SC and STK1AW32SC\
		unload-module module-alsa-card\
		load-module module-alsa-sink device=hw:0,2
		}' /etc/pulse/default.pa
		pulseaudio -k
		pulseaudio --start
	fi
fi

if grep -Rq "#assistive" /etc/java-*-openjdk/accessibility.properties; then
	echo "Assistive Technologies already disabled"
else
	echo "Disabling Assistive Technologies"
	sudo sed -i "s/^assistive_technologies=/#&/" /etc/java-*-openjdk/accessibility.properties
fi

echo "Disabling automatic check for updates"
sudo sed -i 's/APT::Periodic::Update-Package-Lists "1"/APT::Periodic::Update-Package-Lists "0"/' /etc/apt/apt.conf.d/20auto-upgrades



# 'Disable' Chromium updates
touch /etc/chromium-browser/customizations/01-disable-update-check
echo CHROMIUM_FLAGS=\"\$\{CHROMIUM_FLAGS\} --check-for-update-interval=31536000\" > /etc/chromium-browser/customizations/01-disable-update-check

quote="'"

echo '#!/bin/bash' >run.sh
echo 'unclutter -idle 5.0 -root &' >>run.sh
echo 'killall chromium-browser &>/dev/null' >>run.sh
echo 'sed -i '$quote's/"exited_cleanly": false/"exited_cleanly": true/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
echo 'sed -i '$quote's/"exit_type": "Crashed"/"exit_type": "None"/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
echo 'cd eSignJava' >>run.sh
echo 'java -cp .:json.jar eSign' >>run.sh

chmod +x run.sh

FILE=eSignJava.zip

# should handle if the eSignJava has been downloaded already

if [ -f "$FILE" ]; then
	echo "$FILE exists (1)."
else 
	wget 'https://www.planetestream.co.uk/files/eSignJava.zip' &>/dev/null
	#wget 'http://files.planetestream.org/files/eSignJava.zip' 
	#curl -L 'https://www.planetestream.co.uk/files/eSignJava.zip' --output 'eSignJava.zip'
fi

if [ -f "$FILE" ]; then
	echo "$FILE exists (2)."
else 
	echo "There was an error downloading $FILE, exiting."
	exit 1
fi

unzip -o -j 'eSignJava.zip' -d ~/eSignJava &>/dev/null

cd eSignJava

echo "Compiling eSign Client"
javac -cp .:json.jar main.java

cd ~/

rm 'eSignJava.zip'

# Attempts to set the default browser to Chrome to prevent the notification that shows without user intervention
if grep -Rq "text/html=chromium-browser.desktop" .config/mimeapps.list; then
	echo "Chrome default already set"
else
	echo "Setting Chromium to default browser"
	echo '[Default Applications]' >>.config/mimeapps.list
	echo 'text/html=chromium-browser.desktop' >>.config/mimeapps.list
	echo 'x-scheme-handler/http=chromium-browser.desktop' >>.config/mimeapps.list
	echo 'x-scheme-handler/https=chromium-browser.desktop' >>.config/mimeapps.list
	echo 'x-scheme-handler/about=chromium-browser.desktop' >>.config/mimeapps.list
	echo 'x-scheme-handler/unknown=chromium-browser.desktop' >>.config/mimeapps.list
fi

mkdir .config/autostart 1>/dev/null

if [ -f ".config/autostart/run.sh.desktop" ]; then
	echo "Autostart file exists"
else
	echo "Setting client to autostart"
	echo '[Desktop Entry]' >>.config/autostart/run.sh.desktop
	echo 'Type=Application' >>.config/autostart/run.sh.desktop
	echo 'Exec='${HOME}'/run.sh' >>.config/autostart/run.sh.desktop
	echo 'Hidden=false' >>.config/autostart/run.sh.desktop
	echo 'NoDisplay=false' >>.config/autostart/run.sh.desktop
	echo 'X-GNOME-Autostart-enabled=true' >>.config/autostart/run.sh.desktop
	echo 'Name[en_GB]=eSign' >>.config/autostart/run.sh.desktop
	echo 'Name=eSign' >>.config/autostart/run.sh.desktop
	echo 'Comment[en_GB]=' >>.config/autostart/run.sh.desktop
	echo 'Comment=' >>.config/autostart/run.sh.desktop
fi

if sudo grep -Rq "reboot" /etc/sudoers; then
	echo "Sudo permissions already set"
else
	echo 'Adding the current user to sudoers to allow reboot commands'
	sudo sh -c "echo \"${USER} ALL=(ALL) NOPASSWD: /sbin/reboot\" >> /etc/sudoers"
fi

echo 'The Planet eSign Client has now been installed'
echo 'You can run the client manually by running: ./run.sh'
echo 'Or by rebooting the device'
echo 'Please note it is recommended to reboot the device if kernel updates were applied'
echo ''

# Reboot to start esign
#reboot

#echo -e "\e[1;31m **** Please run the following command to install the ESign client! **** \e[0m"
#wget -qO- https://planetestream.co.uk/files/install_esign.sh | bash -
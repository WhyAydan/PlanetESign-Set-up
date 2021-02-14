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

# OS Detector

detect_os() {
	if [[ (-z "${os}") && (-z "${dist}") ]]; then
		# some systems dont have lsb-release yet have the lsb_release binary and
		# vice-versa
		if [ -e /etc/lsb-release ]; then
			. /etc/lsb-release

			if [ "${ID}" = "raspbian" ]; then
				os=${ID}
				dist=$(cut --delimiter='.' -f1 /etc/debian_version)
			else
				os=${DISTRIB_ID}
				dist=${DISTRIB_CODENAME}

				if [ -z "$dist" ]; then
					dist=${DISTRIB_RELEASE}
				fi
			fi

		elif [ $(which lsb_release 2>/dev/null) ]; then
			dist=$(lsb_release -c | cut -f2)
			os=$(lsb_release -i | cut -f2 | awk '{ print tolower($1) }')

		elif [ -e /etc/debian_version ]; then
			# some Debians have jessie/sid in their /etc/debian_version
			# while others have '6.0.7'
			os=$(cat /etc/issue | head -1 | awk '{ print tolower($1) }')
			if grep -q '/' /etc/debian_version; then
				dist=$(cut --delimiter='/' -f1 /etc/debian_version)
			else
				dist=$(cut --delimiter='.' -f1 /etc/debian_version)
			fi

		elif [ -e /etc/centos-release ]; then
			os='centos'

		elif [ -f /etc/os-release ]; then
			source /etc/os-release
			if [ -n "${PRETTY_NAME}" ]; then

				os=${PRETTY_NAME}
			else

				[[ -n "${VERSION}" ]] && printf " ${VERSION}"

				os=${NAME}
			fi

		else
			unknown_os
		fi
	fi

	if [ -z "$dist" ]; then
		unknown_os
	fi

	# remove whitespace from OS and dist name
	os="${os// /}"
	dist="${dist// /}"

	#echo "Detected operating system as $os."
}

# Depenacy Checker

check_deps() {
	if [[ $(which java) ]]; then
		echo 'Java exists'
	else
		echo 'Java does not exist'
		exit 1
	fi

	if [[ $(which chromium-browser) ]]; then
		echo 'Chromium exists'
	else
		echo 'Chromium does not exist'
		exit 1
	fi
}

# Welcome Text

welcome_text() {
	echo 'Welcome to the Planet eStream Digital Signage Client Linux installer'
	echo 'This will install the necessary software dependencies for the Digital Signage Client to run'
	echo 'OS Updates will be applied during this installation'
	echo 'The installer will request escalation for running updates and installation of dependencies'
	echo 'The client will be set to run at logon'
	echo 'Please set a user to login automatically'
	echo 'If you have any questions regarding the client please contact either Aydan or Kyle on:'
	echo 'Email: aabrahams@cmatrust.net, kmarchant@cmatrust.net'
	echo ' '
}

main() {
	welcome_text
	detect_os

	echo "Checking network connection"
	if nc -zw1 planetestream.co.uk 443; then
		echo "Network connectivity found!"
	else
		echo "No network connection found, please check that access to the internet has been provided."
		exit
	fi

	if [ $os == "Ubuntu" ]; then
		echo "Ubuntu detected"
		# The update manager application is known to load automatically, this locks the various tools used in this script.
		killall update-manager &>/dev/null

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
	else
		echo 'Operating system type not detected, please contact Aydan Abrahms for help'
		exit
	fi

	check_deps

	quote="'"

	echo '#!/bin/bash' >run.sh
	echo 'unclutter -idle 5.0 -root &' >>run.sh
	echo 'killall chromium-browser &>/dev/null' >>run.sh
	#printf 'perl -pi -e ''s/exit_type\":\"Crashed/exit_type\":\"none/'' ~/.config/chromium/Default/Preferences'
	#echo 'perl -pi -e '$quote's/exit_type\":\"Crashed/exit_type\":\"none/'$quote' ~/.config/chromium/Default/Preferences' >>run.sh
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
}

main

# Reboot to start esign
#reboot

#echo -e "\e[1;31m **** Please run the following command to install the ESign client! **** \e[0m"
#echo -e "\e[1;31m wget -qO- https://planetestream.co.uk/files/install_esign.sh | bash - \e[0m"
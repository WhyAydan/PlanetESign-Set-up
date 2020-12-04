#!/bin/sh

#This script *should* install VNC and get it set up

#Written by KMA

echo "Running as "$(whoami)

autovncDeps = " git psmisc"

if [ $(whoami) != "root" ];
then
    echo "Please run with sudo!"
    exit 3

fi

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
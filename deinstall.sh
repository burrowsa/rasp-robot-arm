#! /bin/bash
sudo cp /etc/dhcpcd.conf.orig /etc/dhcpcd.conf
sudo cp /etc/network/interfaces.orig /etc/network/interfaces
sudo rm /etc/hostapd/hostapd.conf 
sudo cp /etc/default/hostapd.orig  /etc/default/hostapd
sudo cp /etc/dnsmasq.conf.orig /etc/dnsmasq.conf
touch crontab
crontab crontab
rm crontab
sudo reboot

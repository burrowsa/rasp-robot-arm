#! /bin/bash 
# Sets up a raspberry pi running rasbian 2017-01-11 as a wifi acess point with a captive portal running the
# robot arm webapp
#
# Based on instructions at https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/
# and http://sirlagz.net/2013/08/23/how-to-captive-portal-on-the-raspberry-pi/

export SSID=robot-arm
# If you want a passphrase it must be at least 8 characters long
export PASSPHRASE=

sudo apt-get update

sudo apt-get install -y dnsmasq hostapd

sudo pip3 install flask uwsgi pyusb

if [ ! -f /etc/dhcpcd.conf.orig ]; then
    sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.orig
fi

sudo echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

if [ ! -f /etc/network/interfaces.orig ]; then
    sudo cp /etc/network/interfaces /etc/network/interfaces.orig
fi

head -n -7 /etc/network/interfaces.orig | sudo tee /etc/network/interfaces > /dev/null

cat | sudo tee -a /etc/network/interfaces > /dev/null <<EOL
allow-hotplug wlan0
iface wlan0 inet static
    address 10.0.0.1
    netmask 255.255.255.0
    network 10.0.0.0
    broadcast 10.0.0.255
#    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf

allow-hotplug wlan1
iface wlan1 inet manual
    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOL


if [ -z "$PASSPHRASE" ]; then

cat | sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOL
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
EOL

else

cat | sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOL
interface=wlan0
driver=nl80211
ssid=$SSID
hw_mode=g
channel=6
ieee80211n=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_passphrase=$PASSPHRASE
rsn_pairwise=CCMP
EOL

fi


if [ ! -f /etc/default/hostapd.orig ]; then
    sudo cp /etc/default/hostapd /etc/default/hostapd.orig
fi


sudo sed -i "s/#DAEMON_CONF=\"\"/DAEMON_CONF=\"\/etc\/hostapd\/hostapd.conf\"/" /etc/default/hostapd

if [ ! -f /etc/dnsmasq.conf.orig ]; then
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
fi

cat | sudo tee /etc/dnsmasq.conf > /dev/null <<EOL
interface=wlan0      # Use interface wlan0  
listen-address=10.0.0.1 # Explicitly specify the address to listen on  
bind-interfaces      # Bind to the interface to make sure we aren't sending things elsewhere  
server=8.8.8.8       # Forward DNS requests to Google DNS  
domain-needed        # Don't forward short names  
bogus-priv           # Never forward addresses in the non-routed address spaces.  
dhcp-range=10.0.0.50,10.0.0.150,12h # Assign IP addresses between 10.0.0.50 and 10.0.0.150 with a 12 hour lease time
address=/#/10.0.0.1
EOL

crontab -l > crontab

echo "@reboot cd $PWD; sudo /usr/local/bin/uwsgi --http 0.0.0.0:80 --module robot.app --callable app" >> crontab

crontab crontab
rm crontab

sudo reboot

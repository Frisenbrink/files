#!/bin/sh
UUID=$(cat /proc/sys/kernel/random/uuid)
INSTALL_PKGS="python3-pip default-jdk unzip chrony"
echo '**************************************'
echo 'Automagical Anura gateway setup.'
echo '**************************************'
echo 'Create temp install directory and cd into it.'
mkdir anurasetup
cd anurasetup
echo '**************************************'
echo 'Update and install packages'
echo '**************************************'
sudo apt-get update
echo 'Install apt packages defined in INSTALL_PKGS'
for i in $INSTALL_PKGS; do
  sudo apt-get install -y $i
done
echo '**************************************'
echo 'Apt packages installed.'
java -version
echo '**************************************'
echo 'Aws-cli installation.'
echo '**************************************'
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
echo '**************************************'
./aws/install
echo 'Aws-cli installed.'
echo '**************************************'
echo 'Setup AWS credentials.'
echo '**************************************'
echo 'Please input aws access key.'
read -p 'aws_access_key: ' aws_access_key
export AWS_ACCESS_KEY_ID=$aws_access_key
echo 'Please input secret access key'
read -p 'secret_access_key: ' secret_access_key
export AWS_SECRET_ACCESS_KEY=$secret_access_key
echo 'AWS credentials setup'
echo '**************************************'
echo 'Download and setup Greengrass software'
echo '**************************************'
curl -s https://d2s8p88vqu9w66.cloudfront.net/releases/greengrass-2.5.6.zip > greengrass-nucleus-latest.zip
unzip greengrass-nucleus-latest.zip -d GreengrassCore
#echo 'Please input thing group.'
#read -p 'thing_group: ' thing_group
echo 'Installing Greengrass.'
sudo -E java -Droot="/greengrass/v2" -Dlog.store=FILE -jar ./GreengrassCore/lib/Greengrass.jar --aws-region eu-central-1 --thing-name $UUID --thing-group-name testThingroup --component-default-user ggc_user:ggc_group --provision true --setup-system-service true --deploy-dev-tools true
echo '**************************************'
echo 'Binding serial ports for RaspberryPi4'
echo '**************************************'
echo 'KERNEL=="ttyACM*", KERNELS=="1-1.3:1.0", SYMLINK+="Anura_Receiver1"' | sudo tee -a /etc/udev/rules.d/99-usb-serial.rules
echo 'KERNEL=="ttyACM*", KERNELS=="1-1.4:1.0", SYMLINK+="Anura_Receiver2"' | sudo tee -a /etc/udev/rules.d/99-usb-serial.rules
sudo udevadm control --reload-rules
sleep 1
echo '**************************************'
echo 'Setup NTP server'
echo '**************************************'
sudo sed -i "s/pool 2.debian.pool.ntp.org iburst/pool ntp.se iburst/g" /etc/chrony/chrony.conf
#sudo systemctl enable chronyd
sudo timedatectl set-timezone Europe/Stockholm
echo '**************************************'
echo 'creaste service for 100Mb network'
echo '**************************************'
echo '[Unit]
Description=ethtool configuration to enable 100mbps speed for the specified card
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/sbin/ethtool -s eth0 advertise 0x008
Type=oneshot

[Install]
WantedBy=multi-user.target' | sudo tee -a /etc/systemd/system/ethtool@eth0.service
# Start the service
sudo systemctl enable ethtool@eth0.service
echo '**************************************'
echo 'Cleanup files.'
echo '**************************************'
cd ../
yes | rm -r anurasetup
echo '**************************************'
echo 'Anura Gateway setup done!'
echo 'Please reboot RaspberryPI'
echo 'Login to AWS for further configuration.'
echo '**************************************'
exit

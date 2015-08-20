DEBIAN_FRONTEND=noninteractive

echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

## Cleaning unneeded packages
apt-get -y remove linux-headers-$(uname -r) build-essential ruby-dev
apt-get -y autoremove
apt-get -y clean

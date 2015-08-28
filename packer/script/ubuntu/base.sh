export DEBIAN_FRONTEND=noninteractive

if [ -f /etc/lsb-release ]; then
  . /etc/lsb-release
fi

apt-get update
apt-get -y install curl

sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=sudo' /etc/sudoers
sed -i -e 's/%sudo  ALL=(ALL:ALL) ALL/%sudo  ALL=NOPASSWD:ALL/g' /etc/sudoers

echo "UseDNS no" >> /etc/ssh/sshd_config

# Install Puppet Source
if [ -f /etc/apt/sources.list.d/puppetlabs.list ]; then
  rm /etc/apt/sources.list.d/puppetlabs.list
fi

if [ ! -f /etc/apt/sources.list.d/puppetlabs-pc1.list ]; then
  curl -O http://apt.puppetlabs.com/puppetlabs-release-pc1-${DISTRIB_CODENAME}.deb
  dpkg -i puppetlabs-release-pc1-${DISTRIB_CODENAME}.deb
fi

apt-get update
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install unzip wget ruby ruby-dev git
apt-get -y install puppet-agent ruby-bundler unzip wget ruby ruby-dev git
gem install bundler deep_merge --no-ri --no-rdoc

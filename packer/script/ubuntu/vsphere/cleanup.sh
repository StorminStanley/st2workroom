#!/usr/bin/env bash

echo "Removing root user authorized keys..."
rm -rf /root/.ssh/authorized_keys

echo "Removing all user authorized keys..."
for user in `ls /home`; do
  rm -rf /home/$user/.ssh/authorized_keys
done



echo "Shredding SSH host key pairs..."
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub

## Ensure Host Keys are re-generated on first boot
echo "dpkg-reconfigure openssh-server" >> /etc/rc.local

### This must be done after password cleanup
## During first boot, there is a period of time where
## the machine is configuring itself for the installer
## to be run. This user exists until StackStorm
## is up and running

# See LastPass for bootstrap password
USER="bootstrap"
PASSWORD_HASH='$6$fyfRT6IWkc7IYC8$JSpW3AQuM6XFtfy5lFTRoThVBSYgZiZWJvU0.5D0WpqSsyML/U3dBbX9XB1doKh1tA/73j77Ghs0jNF9adwh7.'

echo "Setting failsafe bootstrap user..."
useradd --create-home $USER
usermod -p $PASSWORD_HASH $USER

## Ensure provisioning user is locked to avoid security leak.
## This is a bit of a hack, because the bootstrap user
## needs access until Packer is done, so this needs to happen on
## first boot.
echo "usermod -L vagrant" >> /etc/rc.local

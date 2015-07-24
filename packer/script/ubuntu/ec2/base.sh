#!/bin/sh

# Notes at https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/building-shared-amis.html

export DEBIAN_FRONTEND=noninteractive

date > /etc/build_time

sudo apt-get -y install ec2-api-tools

# Disable root access
sudo passwd -l root

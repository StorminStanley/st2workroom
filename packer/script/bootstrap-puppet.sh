#!/usr/bin/env bash
# This stand-alone script should be able to be used to kickstart a new node

PROJECT_ROOT=/opt/puppet
GH_TOKEN=9a579d54cef221d192c62b7d8a1f6bd6007fac6c
export DEBIAN_FRONTEND=noninteractive

# Install Pre-req for git
if [ -f /usr/bin/apt-get ]; then
  apt-get install -y git
fi

if [ -f /usr/bin/yum ]; then
  yum install -y git-core
fi

if [ ! -f ${PROJECT_ROOT}/.git ]; then
  # Backup the directory in the event that masterless setup goes south
  if [ -d ${PROJECT_ROOT} ]; then
    mv ${PROJECT_ROOT} ${PROJECT_ROOT}.old
  fi
  git clone https://${GH_TOKEN}/github.com/StackStorm/st2enterprise ${PROJECT_ROOT}
fi

# Create Facter sink
if [ ! -d /etc/facter/facts.d ]; then
  echo "Setting up facter.d..."
  mkdir -p /etc/facter/facts.d
fi

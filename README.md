st2workroom
=========

A full fledged development environment for working with StackStorm. This project allows you to:

* Spin up a test environment to play with StackStorm (`st2express`)
* Spin up a development environment to work with StackStorm (`st2dev`)
* Begin building infrastructure patterns using pre-configured Config Management tools

# Requirements:

* Vagrant - [version 1.7.2 or higher](https://www.vagrantup.com/downloads.html). (See https://github.com/mitchellh/vagrant/issues/3769)

## Project Goals

The goal of this project is to have a workspace that allows you to develop infrastructure in conjuction
with StackStorm, or even work on the StackStorm product itself. This project also serves as a template
to be used to begin building out and deploying infrastructure using your favorite Configuration Management
tool in conjunction with StackStorm

Currently, the project has support for the following Config Management Tools:

* Puppet

Additional workrooms will be created for the following languages:

* Chef
* Ansible
* Salt

## Usage
### st2express

st2express is used to spin up a test StackStorm instance. To start, simply type the following command:

```
  vagrant up st2express
```

This will automatically provision a new StackStorm server. If you have Bonjour/Zeroconf enabled on your
machine, the WebUI will be available at http://st2express.local:9101/

To SSH into the machine, simply type the following command:

```
  vagrant ssh st2express
```

### st2dev

st2dev is used as a clean room environment to develop StackStorm against. This machine downloads all
the necessary dependencies, as well as Mistral.

To start the machine, simply type the following command

```
  vagrant up st2dev
```

To SSH into the machine, simply type the following command:

```
  vagrant ssh st2dev
```

## Configuration
### Virtual Machine configuration
In the event you would like to develop or test a different target machine, or need to change the
number of CPUs/RAM... all of these settings are configured in `stacks/st2.yaml`. Take a look at
the `defaults` section and adjust accordingly.

### ChatOps

By default, both `st2express` and `st2dev` come with installed copies of Hubot. This is to allow
local testing of ChatOps. To configure Hubot, simply take a look at the file `hieradata/workroom.yaml`.
You will see all of the configuration commented out. To setup Hubot to automatically connect to an
IRC room, for example, simply set the following values in `hieradata/workroom.yaml`

```
hubot::adapter: irc
hubot::env_export:
  HUBOT_LOG_LEVEL: DEBUG
  HUBOT_IRC_SERVER: "irc.freenode.net"
  HUBOT_IRC_ROOMS: "#stackstorm"
  HUBOT_IRC_NICK: "hubot-stanley"
  HUBOT_IRC_UNFLOOD: true
hubot::dependencies:
  hubot: ">= 2.6.0 < 3.0.0"
  "hubot-scripts": ">= 2.5.0 < 3.0.0"
  "hubot-irc": ">= 0.2.7"
```

Refer to https://github.com/github/hubot/blob/master/docs/adapters.md for additional information about
Hubot Adapters

Hubot by default is installed at `/opt/hubot`

### Development Directories
In the `st2dev` environment, the image makes no attempt to download code for you. Instead, it is
assumed that most development will be happening on the host machine, and as such you will need to grab
StackStorm code directly.

Our recommendation: specify a mountpoint in the file `stacks/st2.yaml` under the `st2dev` key. This will
automatically setup an NFS mount, and makes it easy to do development locally. Learn more about how stacks work
by reading STACKS.md. For example, here is what it looks like to mount my local StackStorm install:

```yaml
# stacks/st2.yaml
---
st2dev:
  <<: *defaults
  hostname: st2dev
  # Any number of facts available to the server can be set here
  puppet:
    facts:
      role: st2dev
  mounts:
    - "/mnt/st2:/Users/jfryman/stackstorm/st2"
```

NOTE: You may be asked for permission to make modifications to the Host's `/etc/exports` file.

### Adding Users
By default, the `stanley` user is added to both the `st2express` and `st2dev` roles. This
user is installed with default SSH keys that are insecure and not meant to be used in
production. If you would like to change these keys, take a look at the `st2::stanley`
keys located in `hieradata/workroom.yaml`

For example, to change the SSH Keys for the `stanley` user:

```
# hieradata/workroom.yaml
st2::stanley::ssh_public_key: XXXXXX
st2::stanley::ssh_key_type: ssh-rsa
st2::stanley::ssh_private_key: XXXXXX
```


However, there may exist times where you want to add a local user to the box. To do
this, simply add an entry to `hieradata/workroom.yaml` under the `users` key.

For example, to add a new user, simply:

```
# hieradata/workroom.yaml
users:
  manas:
    uid: 700
    gid: 700
    sshkey: XXXXXX
    sshkeytype: ssh-rsa
    shell: /bin/bash
    admin: true
```

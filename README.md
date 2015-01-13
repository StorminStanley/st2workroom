st2-puppet-seed
=========

This is currently a masterless Puppet Repository. It can be used in a Vagrant environment or on a server machine.

## Usage

A script is copied to `/usr/bin/puprun`, which will be used to do branch updates based on upstream `git`,
and act as the masterless executor.

Puppet can run a series of environments, covered by `git` branching. To deploy a specific branch, simply
set the environment variable `environment` and off you go!

Example:
```
environment=myawesomechange puprun
```

The node will stay on the `myawesomechange` branch until:
* The branch is deleted from upstream, where it will automatically revert back to `production`, or...
* You specify another branch to run as illustrated above

## Environment Variables
Vagrant uses the `dotenv` gem to allow persistent storage of variables to be used.

Place any variables in the `.env` file at the top level of this project

## Vagrant

Vagrant also able to be super flexible. By default, a branch known as `current_working_directory` is
created and used as the environment for Puppet to run in. This prevents you from having to `git commit`
and push upstream to make and test local changes.

Vagrant has the ability to mock out different nodes, as well as different environments. Simply use the
`hostname` and `environment` variables as appropriate.

Vagrant also has the ability to dynamically switch out Vagrant Baseboxes. Use the `box` environment
variable to change it up. (More details can be found inside the `Vagrantfile`)

Example:
```
hostname=ops001 box=fedora vagrant up
```

The node will remain named `ops001.stackstorm.net` and running on Fedora until it is destroyed

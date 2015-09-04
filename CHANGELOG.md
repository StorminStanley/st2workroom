# Changelog

## In Development
* Fix: st2ctl causing issues with Startup status after install (*bugfix*)
* Flag to disable Hubot installation via installer (*improvement*)
* Fix: st2auth service not starting on correct IP address (*bugfix*)
* update pip to latest on installation (*improvement*)

## v0.2.2 / Aug 30, 2015
* Fix mongodb/rabbitmq OS packages from reinstalling/restarting in a loop (*bugfix*)
* Fix connection errors when host machine does not have FQDN defined (*bugfix*)
* Fix StackStorm service authentication failure on host rename (*bugfix*)
* Fix `update-system` removing system user information (*bugfix*)

## v0.2.1 / Aug 29, 2015
* Remove unnecessary `fail` on deprecation convergence logic. (*bugfix*)
* Keep existing `sudoers` entries on host during installation (*bugfix*)
* Stop managing `puppet` and `mcollective` services with masterless (*bugfix*)
* Fix `check-st2-ok: line 4: facter: command not found` (*bugfix*)

## v0.2.0 / Aug 28, 2015

* Remove 'cache_libraries' flag from puppet runner (*bugfix*)
* Migrate MongoDB and RabbitMQ to Containers (*improvement*)
* Automatically install Vagrant plugins if missing on host (*improvement*)
* Fix KV registration during Installation (*bugfix*)
* Fix `sync_type` host to guest file sync for puppet manifests (*bugfix*)

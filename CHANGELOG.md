# Changelog

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

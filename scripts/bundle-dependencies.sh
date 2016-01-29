#!/usr/bin/env bash

# Script which updates bundled Puppet dependencies in vendor/puppet/cache/*
# and updates Puppetfile.lock based on the values in Puppetfile
bundle exec librarian-puppet package --verbose

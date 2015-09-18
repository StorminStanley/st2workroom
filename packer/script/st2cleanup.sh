#!/usr/bin/env bash

# Stop all services
service mistral stop
service st2actionrunner stop
service st2api stop
service st2auth stop
service st2notifier stop
service st2resultstracker stop
service st2rulesengine stop
service st2sensorcontainer stop
service st2web stop
service rabbitmq-server stop
service mongodb stop

# Cleanup any logfiles
echo "Removing all log files..."
rm -rf /var/log/st2/*

# Get rid of RabbitMQ Data and recreate on startup
# Needed if hostname changes.
echo "Cleaning RabbitMQ Queue data..."
rm -rf /var/lib/rabbitmq/mnesia/*

# Get rid of MongoDB data and recreate on startup
# Needed because of space savings
echo "Removing MongoDB data..."
rm -rf /var/lib/mongodb/*

# Get rid of any user-generated SSL certs
# Needed if hostname changes
echo "cleaning up ssl certs for first run"
rm -rf /etc/ssl/st2.*

# Other cleanup
rm -rf /root/.cache
rm -rf /opt/puppet/.tmp
rm -rf /opt/puppet/vendor/bundle
rm -rf /opt/puppet/environments/*
rm -rf /opt/puppet/hieradata/credentials.*
rm -rf /var/log/puppet.log

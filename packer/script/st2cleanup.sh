#!/usr/bin/env bash

# Stop all services
components=(st2actionrunner st2sensorcontainer st2api st2auth st2resultstracker st2rulesengine mistral st2web rabbitmq-server mongodb st2notifier)
for i in "${components[@]}"; do
  service $i stop
done

# Cleanup any logfiles
echo "Removing all log files..."
rm -rf /var/log/st2/*

# Get rid of RabbitMQ Data and recreate on startup
# Needed if hostname changes.
echo "Cleaning RabbitMQ Queue data..."
rm -rf /var/lib/rabbitmq/mnesia/*

# Get rid of any user-generated SSL certs
# Needed if hostname changes
echo "cleaning up ssl certs for first run"
rm -rf /etc/ssl/st2.*

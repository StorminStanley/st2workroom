#!/usr/bin/env sh

# Ensure the "credentials" file exists, and is writable.
CREDENTIAL_FILE=/opt/puppet/hieradata/credentials.yaml
touch $CREDENTIAL_FILE
chmod 666 $CREDENTIAL_FILE

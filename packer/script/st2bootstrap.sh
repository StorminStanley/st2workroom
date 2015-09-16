#!/usr/bin/env sh


# Ensure that the ubuntu user passes through AWS_ACCESS_KEY
# and AWS_SECRET_ACCESS_KEY

SUDOERS_FILE=/etc/sudoers.d/st2bootstrap2bootstrap
ENV_VARS="AWS_ACCESS_KEY AWS_SECRET_ACCESS_KEY"

echo "Defaults:ubuntu env_keep += \"${ENV_VARS}\"" >> $SUDOERS_FILE

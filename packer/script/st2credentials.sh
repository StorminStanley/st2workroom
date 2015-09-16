#/usr/bin/env sh

HIERAFILE=/opt/puppet/hieradata/credentials.yaml

if [ -n "$AWS_ACCESS_KEY" ]; then
  echo "aws::access_key: ${AWS_ACCESS_KEY}" >> $HIERAFILE
fi

if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "aws::secret_access_key: ${AWS_SECRET_ACCESS_KEY}" >> $HIERAFILE
fi

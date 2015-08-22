#!/usr/bin/env bash

echo "Removing root user authorized keys..."
rm -rf /root/.ssh/authorized_keys

echo "Removing all user authorized keys..."
for user in `ls /home`; do
  rm -rf /home/$user/.ssh/authorized_keys
done

echo "Shredding SSH host key pairs..."
shred -u /etc/ssh/*_key /etc/ssh/*_key.pub

echo "Removing all user passwords..."
for i in `cat /etc/shadow`; do
	USER=`echo $i | awk '{split($0,a,":"); print a[1]}'`
	PWHASH=`echo $i | awk '{split($0,a,":"); print a[2]}'`

	if [[ "${PWHASH}" == \$* ]]; then
	  passwd -l $USER
	fi
done

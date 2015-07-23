#!/bin/sh

date > /etc/build_time

echo "ubuntu ALL=(ALL) NOPASSWD: SETENV: ALL" >> /etc/sudoers

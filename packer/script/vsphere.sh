#!/bin/sh

date > /etc/box_build_time
echo "stackstorm    ALL=(ALL) NOPASSWD: SETENV: ALL" >> /etc/sudoers

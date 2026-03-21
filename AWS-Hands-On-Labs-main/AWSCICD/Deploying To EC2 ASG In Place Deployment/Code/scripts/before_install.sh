#!/bin/bash
set -e
# Stop the existing application if running
sudo systemctl stop myapp.service || true
sudo pkill -f 'java -jar' || true
echo "BeforeInstall hook completed."
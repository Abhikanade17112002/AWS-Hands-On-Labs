#!/bin/bash
set -e
cd /opt/myapp
# Start the application as ec2-user
sudo -u ec2-user nohup java -jar myapp.jar > /var/log/myapp.log 2>&1 &
# Save the PID for potential later use
echo $! > /var/run/myapp.pid
# Wait a few seconds for the app to initialize
sleep 15
echo "ApplicationStart hook completed."
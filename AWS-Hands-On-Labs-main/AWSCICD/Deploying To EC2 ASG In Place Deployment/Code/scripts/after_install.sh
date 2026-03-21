# #!/bin/bash
# set -e
# # Create application directory if not exists
# sudo mkdir -p /opt/myapp
# # Copy the JAR file (CodeDeploy places files in /home/ec2-user/bluegreen/target/)
# sudo cp /home/ec2-user/bluegreen/target/demo-*.jar /opt/myapp/myapp.jar
# # Set ownership (adjust user if needed)
# sudo chown ec2-user:ec2-user /opt/myapp/myapp.jar
# echo "AfterInstall hook completed."




#!/bin/bash
set -e
# Create application directory if not exists
sudo mkdir -p /opt/myapp
# Copy the JAR file (now named demo.jar - no wildcard)
sudo cp /home/ec2-user/bluegreen/target/demo.jar /opt/myapp/myapp.jar
# Set ownership
sudo chown ec2-user:ec2-user /opt/myapp/myapp.jar
echo "AfterInstall hook completed."
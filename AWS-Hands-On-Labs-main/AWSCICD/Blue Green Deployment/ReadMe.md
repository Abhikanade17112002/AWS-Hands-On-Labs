# Lab 4: Blue/Green Deployments with CodeDeploy to Auto Scaling Group

## Objective
Perform a **blue/green deployment** to an **Auto Scaling group** using **AWS CodeDeploy**, with an **Application Load Balancer** (ALB). We will deploy a simple **Java (Spring Boot)** application and then update it using a blue/green strategy to minimize downtime and enable instant rollback.

---

## Overview

- **Blue/Green Deployment**: Two identical environments (blue = current, green = new). Traffic is shifted from blue to green after the new version is verified.
- **AWS CodeDeploy**: Fully managed deployment service that automates code deployments to instances.
- **Auto Scaling Group**: Ensures the application runs on a fleet of EC2 instances that can scale.
- **Application Load Balancer**: Distributes incoming traffic across targets (instances) and enables traffic shifting during blue/green deployment.

In this lab, we will:
1. Set up the network infrastructure (VPC, subnets, security groups).
2. Create an ALB and target groups.
3. Create an Auto Scaling group (initial green environment).
4. Prepare a Java Spring Boot application with deployment scripts.
5. Package and upload the application to Amazon S3.
6. Create a CodeDeploy application and deployment group configured for blue/green.
7. Deploy the initial version.
8. Update the application and perform a blue/green deployment.
9. Verify and clean up.

---

## Prerequisites

- AWS account with administrative access.
- AWS CLI installed and configured (`aws configure`).
- Java 11+ and Maven installed.
- Git (optional) to clone sample code.
- Basic understanding of EC2, Auto Scaling, Load Balancers, IAM, and S3.

---

## Architecture Diagram

![Blue/Green with CodeDeploy and ASG](https://docs.aws.amazon.com/codedeploy/latest/userguide/images/blue-green-deployment.png)

- **Green (current)**: Running old version behind ALB.
- **Blue (new)**: Launched by CodeDeploy with new version, registered with a separate target group.
- After validation, traffic is shifted from green to blue.

---

## Step 1: Set Up Environment

### 1.1 Create a VPC
We'll use the default VPC or create a new one with public subnets. For simplicity, use default VPC.

```bash
# Get default VPC ID
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text
```

### 1.2 Create Security Groups
Create two security groups: one for the load balancer (allows HTTP from anywhere) and one for EC2 instances (allows HTTP from the load balancer and SSH from your IP).

**Load Balancer Security Group** (`sg-lb`):
- Inbound: HTTP (80) from 0.0.0.0/0

**EC2 Security Group** (`sg-app`):
- Inbound: HTTP (80) from `sg-lb` (or from 0.0.0.0/0 for simplicity)
- Inbound: SSH (22) from your IP (optional, for debugging)

Create them using AWS Console or CLI. Save the security group IDs.

### 1.3 Create IAM Roles

#### a. **EC2 Instance Profile Role** (`CodeDeploy-EC2-Instance-Profile`)
Attach policies:
- `AmazonS3ReadOnlyAccess` (to download code from S3)
- `AmazonSSMManagedInstanceCore` (for Systems Manager, optional)
- Trust relationship: `ec2.amazonaws.com`

#### b. **CodeDeploy Service Role** (`CodeDeployServiceRole`)
Attach policy: `AWSCodeDeployRole` (managed policy)
Trust relationship: `codedeploy.amazonaws.com`

Create these roles via IAM console or CLI.

---

## Step 2: Create Application Load Balancer

### 2.1 Create Target Groups
We need **two target groups**: one for green (original) and one for blue (new). They will be used during deployment.

- **Target Group Green**: `tg-green`
  - Target type: Instance
  - Protocol: HTTP, Port 8080
  - VPC: default VPC
  - Health check path: `/actuator/health` (or `/` if you create a simple endpoint)

- **Target Group Blue**: `tg-blue`
  - Same settings as green, but different name.

Create them via EC2 Console -> Target Groups.

### 2.2 Create ALB
- Name: `alb-bluegreen`
- Scheme: internet-facing
- Listeners: HTTP:80 default action forward to **tg-green** (initially)
- Availability Zones: select at least two public subnets
- Security Group: attach `sg-lb`

After creation, note the DNS name (e.g., `alb-bluegreen-123456.elb.amazonaws.com`).

---

## Step 3: Create Auto Scaling Group

### 3.1 Launch Template
Create a launch template for EC2 instances:
- Name: `lt-bluegreen`
- AMI: Amazon Linux 2 (latest)
- Instance type: t2.micro
- Key pair: select or create one (for SSH access)
- Security groups: `sg-app`
- IAM instance profile: `CodeDeploy-EC2-Instance-Profile`
- User data: install Java and CodeDeploy agent (see below)

**User data script**:
```bash
#!/bin/bash
yum update -y
yum install -y java-11-amazon-corretto
# Install CodeDeploy agent
yum install -y ruby wget
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x ./install
./install auto
service codedeploy-agent start
```

Replace region in URL if not `us-east-1`.

### 3.2 Auto Scaling Group
- Name: `asg-bluegreen`
- Launch template: `lt-bluegreen`
- VPC and subnets: select same public subnets as ALB
- Attach to an existing load balancer:
  - Choose `alb-bluegreen`
  - Target group: `tg-green`
- Health checks: ELB health check (grace period 300 seconds)
- Group size: Desired = 2, Min = 2, Max = 4
- Scaling policies: none for now

Wait for instances to launch and become healthy in the target group. You should see them in EC2 console.

---

## Step 4: Prepare Java Application

We'll create a simple Spring Boot application that returns a version string.

### 4.1 Project Structure
```
bluegreen-app/
├── pom.xml
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── example/
│                   └── demo/
│                       └── DemoApplication.java
│                       └── HelloController.java
├── scripts/
│   ├── before_install.sh
│   ├── after_install.sh
│   ├── application_start.sh
│   ├── validate_service.sh
│   └── before_allow_traffic.sh (optional)
└── appspec.yml
```

### 4.2 Code

**pom.xml** (minimal):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>demo</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.0</version>
    </parent>
    <properties>
        <java.version>11</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**DemoApplication.java**:
```java
package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class DemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }
}
```

**HelloController.java** (with version):
```java
package com.example.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @GetMapping("/")
    public String hello() {
        return "Hello from Green (version 1.0.0)";
    }

    @GetMapping("/version")
    public String version() {
        return "1.0.0";
    }
}
```

### 4.3 Deployment Scripts

All scripts should be executable (`chmod +x`). Place them in `scripts/`.

**before_install.sh** (stop any existing service):
```bash
#!/bin/bash
sudo systemctl stop myapp.service || true
sudo pkill -f 'java -jar' || true
```

**after_install.sh** (copy JAR and set permissions):
```bash
#!/bin/bash
# The deployment archive will be extracted to /opt/codedeploy-agent/deployment-root/...
# We'll copy the JAR to a known location
sudo cp /home/ec2-user/bluegreen/target/demo-*.jar /opt/myapp/myapp.jar
sudo chown ec2-user:ec2-user /opt/myapp/myapp.jar
```

**application_start.sh** (start the application):
```bash
#!/bin/bash
cd /opt/myapp
sudo -u ec2-user nohup java -jar myapp.jar > /var/log/myapp.log 2>&1 &
echo $! > /var/run/myapp.pid
sleep 10  # give time to start
```

**validate_service.sh** (health check):
```bash
#!/bin/bash
# Check if the application responds on port 8080
curl -f http://localhost:8080/actuator/health || exit 1
```

### 4.4 AppSpec File

**appspec.yml** (root of archive):
```yaml
version: 0.0
os: linux

files:
  - source: target/demo-1.0.0.jar
    destination: /home/ec2-user/bluegreen/target/

hooks:
  BeforeInstall:
    - location: scripts/before_install.sh
      timeout: 300
      runas: root
  AfterInstall:
    - location: scripts/after_install.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/application_start.sh
      timeout: 300
      runas: root
  ValidateService:
    - location: scripts/validate_service.sh
      timeout: 300
      runas: root
```

### 4.5 Build and Package

```bash
mvn clean package
# Create a zip archive containing the JAR, appspec.yml, and scripts
mkdir -p deployment-package
cp target/demo-*.jar deployment-package/
cp appspec.yml deployment-package/
cp -r scripts deployment-package/
cd deployment-package
zip -r ../app-v1.0.0.zip .
cd ..
```

---

## Step 5: Upload to S3

Create an S3 bucket (e.g., `my-bluegreen-deployments`). Upload the zip:

```bash
aws s3 mb s3://my-bluegreen-deployments
aws s3 cp app-v1.0.0.zip s3://my-bluegreen-deployments/
```

---

## Step 6: Create CodeDeploy Application and Deployment Group

### 6.1 CodeDeploy Application
- Name: `BlueGreenApp`
- Compute platform: EC2/On-premises

```bash
aws deploy create-application --application-name BlueGreenApp --compute-platform Server
```

### 6.2 Deployment Group (Blue/Green)

Key settings:
- **Deployment group name**: `BlueGreenDG`
- **Service role**: `CodeDeployServiceRole`
- **Deployment type**: Blue/green
- **Environment configuration**: Choose **Amazon EC2 Auto Scaling groups**, select `asg-bluegreen`
- **Load balancer**: Enable, choose `tg-blue` and `tg-green` (both)
- **Traffic rerouting**: Choose **Reroute traffic immediately** (or canary)
- **Original instances termination**: Choose **Terminate the original instances after X minutes** (e.g., 5 min)

We'll create via AWS Console (CodeDeploy -> Applications -> BlueGreenApp -> Create deployment group).

After creation, we have a deployment group ready.

---

## Step 7: Initial Deployment (Green)

Deploy version 1.0.0 to the green environment (which is currently running nothing, but ASG has instances). The deployment group is linked to ASG, so CodeDeploy will deploy to all instances in the ASG.

1. In CodeDeploy console, go to application `BlueGreenApp`, deployment group `BlueGreenDG`.
2. Click "Create deployment".
3. Revision location: `s3://my-bluegreen-deployments/app-v1.0.0.zip`
4. Deployment description: "Initial deployment v1"
5. Other options default.
6. Deploy.

Monitor deployment. After success, access the ALB DNS:
```
http://alb-bluegreen-123456.elb.amazonaws.com/
```
Should show "Hello from Green (version 1.0.0)".

---

## Step 8: Update Application (Blue/Green Deployment)

### 8.1 Modify Application for Version 2.0.0

Change `HelloController.java`:
```java
@GetMapping("/")
public String hello() {
    return "Hello from Blue (version 2.0.0)";
}

@GetMapping("/version")
public String version() {
    return "2.0.0";
}
```

Update `pom.xml` version to `2.0.0`. Rebuild and create new zip.

```bash
mvn clean package
# create new zip: app-v2.0.0.zip (adjust version in scripts? The AppSpec references target/demo-*.jar, so it's okay)
```

Upload to S3:
```bash
aws s3 cp app-v2.0.0.zip s3://my-bluegreen-deployments/
```

### 8.2 Perform Blue/Green Deployment

In CodeDeploy console, create a new deployment:
- Revision: `s3://my-bluegreen-deployments/app-v2.0.0.zip`
- Deployment group: `BlueGreenDG`
- (Optional) Override blue/green settings: we can keep as defined in group.

Start deployment.

### 8.3 What Happens?

- CodeDeploy launches a new Auto Scaling group (blue) with the same configuration as the original (green). It installs the new application version on those instances.
- Once instances are healthy in `tg-blue`, CodeDeploy reroutes traffic from `tg-green` to `tg-blue` (according to your traffic shifting setting – immediate or canary).
- After traffic shift, you can validate the new version on the ALB.
- After a waiting period, CodeDeploy terminates the original instances (green ASG).

During deployment, you can monitor the process in CodeDeploy console.

### 8.4 Validation

After deployment completes, refresh the ALB URL. You should see:
```
Hello from Blue (version 2.0.0)
```

Check that traffic is now going to blue instances.

---

## Step 9: Rollback (Optional)

If something goes wrong, you can roll back to the previous version by deploying the old revision again. CodeDeploy will perform another blue/green deployment.

---

## Step 10: Clean Up

To avoid incurring charges, delete resources:

1. Delete CodeDeploy application (optional).
2. Delete Auto Scaling group (first set min/desired to 0, then delete).
3. Delete launch template.
4. Delete load balancer and target groups.
5. Delete security groups.
6. Delete S3 bucket (or just the objects).
7. Delete IAM roles if no longer needed.


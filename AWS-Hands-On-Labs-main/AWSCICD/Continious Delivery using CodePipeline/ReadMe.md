LAB 2
Continuous Delivery with CodePipeline → Elastic Beanstalk
1. Objective

Extend the pipeline so that:

git push
   ↓
CodeCommit
   ↓
CodeBuild (build JAR)
   ↓
CodePipeline
   ↓
Elastic Beanstalk deployment

This means:

Push Code → Build → Deploy Automatically
2. Architecture
Developer
   │
   │ git push
   ▼
CodeCommit
   │
   ▼
CodePipeline
   │
   ▼
CodeBuild
   │
   ▼
Elastic Beanstalk
   │
   ▼
EC2 instance running Java app
3. Prerequisites

From Lab 1 you must already have:

Resource	Name
Repository	java-ci-lab
Build project	java-ci-build
Java project	Maven
Artifact	.jar
PART 1 — Prepare Elastic Beanstalk
Step 1 — Open Elastic Beanstalk

Go to:

AWS Elastic Beanstalk

Click:

Create application
Step 2 — Configure Application

Fill:

Field	Value
Application name	java-cicd-app

Click:

Create
Step 3 — Create Environment

Click:

Create environment

Choose:

Web server environment
Step 4 — Choose Platform

Platform:

Java

Platform branch:

Corretto 17

Application code:

Sample application

This will create a working environment first.

Click:

Next
Step 5 — Environment Settings

Fill:

Setting	Value
Environment name	java-cicd-env

Instance type:

t2.micro

Leave defaults.

Click:

Create environment
Step 6 — Wait for Environment Creation

Elastic Beanstalk will create:

EC2 instance

Security group

Load balancer

Auto Scaling

This takes:

3–5 minutes

When finished you will see:

Health: Green

And a URL like:

http://java-cicd-env.ap-south-1.elasticbeanstalk.com
PART 2 — Create CodePipeline
Step 7 — Open CodePipeline

Go to:

AWS CodePipeline

Click:

Create pipeline
Step 8 — Pipeline Settings

Fill:

Field	Value
Pipeline name	java-cicd-pipeline
Execution mode	Superseded

Service role:

Create new role

Click:

Next
PART 3 — Source Stage
Step 9 — Configure Source

Source provider:

CodeCommit

Repository:

java-ci-lab

Branch:

master

Change detection:

Amazon CloudWatch Events

This enables automatic pipeline trigger on commit.

Click:

Next
PART 4 — Build Stage
Step 10 — Configure Build

Provider:

CodeBuild

Project name:

java-ci-build

This uses the build project from Lab 1.

Click:

Next
PART 5 — Deploy Stage
Step 11 — Configure Deployment

Deploy provider:

Elastic Beanstalk

Region:

ap-south-1

Application name:

java-cicd-app

Environment name:

java-cicd-env

Click:

Next
Step 12 — Review Pipeline

Pipeline stages should be:

Source
Build
Deploy

Click:

Create pipeline
PART 6 — First Pipeline Execution

Once created, the pipeline automatically starts.

You will see:

Source → Build → Deploy

Each stage should turn green.

PART 7 — Verify Deployment

Open:

AWS Elastic Beanstalk

Click environment:

java-cicd-env

Open the environment URL.

The application should run.

PART 8 — Test Continuous Delivery

Modify the Java file.

Example:

System.out.println("Pipeline deployed new version!");

Push the change:

git add .
git commit -m "pipeline test"
git push origin master
Step 9 — Watch the Pipeline

Open CodePipeline.

You will see:

Pipeline automatically triggered

Stages run:

Source
Build
Deploy

After completion, Elastic Beanstalk deploys the new version automatically.

What You Achieved

You built a real Continuous Delivery pipeline.

Developer
   │
   │ git push
   ▼
CodeCommit
   ▼
CodePipeline
   ▼
CodeBuild
   ▼
Elastic Beanstalk
   ▼
Running Java Application
What Happens Internally

Elastic Beanstalk performs:

Upload artifact
Stop previous version
Deploy new version
Restart application
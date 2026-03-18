LAB 1
Continuous Integration with CodeCommit and CodeBuild (Java)
1. Lab Goal

The goal of this lab is to implement a Continuous Integration (CI) pipeline.

Whenever a developer pushes code:

Code is stored in a Git repository

The code is automatically built

A JAR artifact is produced

Artifact is stored in S3

2. Architecture
Developer
   │
   │ git push
   ▼
CodeCommit Repository
   │
   ▼
CodeBuild
   │
   ▼
Maven Build
   │
   ▼
JAR Artifact
   │
   ▼
Amazon S3
3. Prerequisites

Before starting ensure you have:

1️⃣ AWS Account

Access to AWS Console.

2️⃣ IAM User with permissions

You should have permissions for:

CodeCommit
CodeBuild
S3
IAM
CloudWatch Logs
3️⃣ Git installed

Check:

git --version
4️⃣ Java installed (optional locally)

Check:

java -version
5️⃣ Maven installed (optional)

Check:

mvn -version
4. Step 1 — Create CodeCommit Repository

Open AWS Console.

Search for CodeCommit.

Open the service.

Click:

Create repository

Fill:

Field	Value
Repository name	java-ci-lab
Description	Java CI demo

Click:

Create
What this step does

This creates a Git repository hosted by AWS.

Just like:

GitHub
Bitbucket
GitLab

But inside AWS.

5. Step 2 — Configure Git Credentials

CodeCommit requires authentication.

Open:

IAM

Navigate:

Users → Your User

Open tab:

Security Credentials

Scroll to section:

HTTPS Git credentials for AWS CodeCommit

Click:

Generate Credentials

You will receive:

Username
Password

Save them.

You will use them for git clone.

6. Step 3 — Clone the Repository

Go to CodeCommit repository page.

Copy:

Clone HTTPS URL

Example:

https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/java-ci-lab
Run command
git clone https://git-codecommit.ap-south-1.amazonaws.com/v1/repos/java-ci-lab

Enter credentials.

Move inside repository:

cd java-ci-lab
7. Step 4 — Create Java Project Structure

Create directories:

mkdir -p src/main/java

Your project should look like:

java-ci-lab
│
├── src
│   └── main
│       └── java
│           └── App.java
│
├── pom.xml
└── buildspec.yml
8. Step 5 — Create Java Application

Create file:

src/main/java/App.java

Code:

public class App {

    public static void main(String[] args) {

        System.out.println("Hello from Java CI Pipeline!");

    }

}
What this program does

It simply prints:

Hello from Java CI Pipeline!

This allows us to verify that the build works correctly.

9. Step 6 — Create Maven Build File

Create file:

pom.xml

Paste:

<project xmlns="http://maven.apache.org/POM/4.0.0">

<modelVersion>4.0.0</modelVersion>

<groupId>com.demo</groupId>
<artifactId>java-ci-lab</artifactId>
<version>1.0</version>

<build>

<plugins>

<plugin>

<groupId>org.apache.maven.plugins</groupId>
<artifactId>maven-compiler-plugin</artifactId>

<version>3.8.1</version>

<configuration>

<source>17</source>
<target>17</target>

</configuration>

</plugin>

</plugins>

</build>

</project>
What Maven does

Maven will:

1️⃣ Compile Java code
2️⃣ Package it
3️⃣ Generate a JAR file

Output will appear in:

target/

Example:

target/java-ci-lab-1.0.jar
10. Step 7 — Create buildspec.yml

This file tells CodeBuild how to build your project.

Create:

buildspec.yml

Add:

version: 0.2

phases:

  install:
    runtime-versions:
      java: corretto17

  pre_build:
    commands:
      - echo Installing dependencies

  build:
    commands:
      - echo Build started
      - mvn clean package

  post_build:
    commands:
      - echo Build finished

artifacts:
  files:
    - target/*.jar
Explanation of buildspec.yml
install phase

Installs Java runtime.

Java Corretto 17
pre_build

Runs before compilation.

Example:

echo Installing dependencies
build phase

Main build command:

mvn clean package

This compiles and packages code.

artifacts

Files that CodeBuild uploads to S3.

target/*.jar
11. Step 8 — Push Code to Repository

Run commands.

git add .

Commit:

git commit -m "Initial Java CI pipeline"

Push:

git push origin main

Now your code is stored in CodeCommit.

12. Step 9 — Create CodeBuild Project

Open:

CodeBuild

Click:

Create build project
Project Configuration

Project name:

java-ci-build
Source
Setting	Value
Source provider	CodeCommit
Repository	java-ci-lab
Branch	main
Environment
Setting	Value
Environment	Managed Image
Operating System	Ubuntu
Runtime	Standard
Image	aws/codebuild/standard:7.0
Compute	Small
Service Role

Choose:

Create new service role

Example name:

codebuild-java-ci-role

This role allows CodeBuild to:

read repository
upload artifacts
write logs
13. Step 10 — Configure Artifacts

Select:

Amazon S3

Create bucket:

Example:

java-ci-artifacts-demo

Packaging:

ZIP
14. Step 11 — Enable Logs

Enable:

CloudWatch Logs

Example log group:

/aws/codebuild/java-ci-build
15. Step 12 — Start Build

Open project.

Click:

Start Build
16. Build Phases

You will see phases:

INSTALL
PRE_BUILD
BUILD
POST_BUILD
UPLOAD_ARTIFACTS
Expected Build Logs

Example:

Installing Java Corretto 17
Build started
[INFO] Building jar
Hello from Java CI Pipeline!
Build finished
Uploading artifacts
Build succeeded
17. Verify Artifact

Open:

S3

Open your artifact bucket.

You will see:

build-output.zip

Inside ZIP:

java-ci-lab-1.0.jar
18. What You Learned
Concept	Explanation
CI	Automated builds
CodeCommit	Git repository
CodeBuild	Build service
Maven	Java build system
buildspec.yml	Build instructions
Artifacts	Build outputs
19. Real Industry Equivalent

This exact pipeline is used in companies:

GitHub
   ↓
Jenkins / CodeBuild
   ↓
Maven Build
   ↓
Artifact Repository



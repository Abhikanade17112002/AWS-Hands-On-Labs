Lab 1: Continuous Integration with CodeCommit and CodeBuild
Objective: Create a CodeCommit repository, set up a CodeBuild project that builds a simple application, and store build artifacts in S3. Understand the basics of source control integration and build specifications.

Step 1: Create a CodeCommit Repository
Go to AWS CodeCommit console → Create repository.

Repository name: MyAppRepo

Description: Sample app for CI/CD

Create.

Note the repository clone URLs (HTTPS or SSH). We'll use HTTPS with Git credentials.

Set up Git credentials for your IAM user:

In IAM console, select your user → Security credentials → HTTPS Git credentials for AWS CodeCommit → Generate credentials.

Download or save the username and password.

Clone the repository locally (or set up remote):

bash
git clone https://git-codecommit.<region>.amazonaws.com/v1/repos/MyAppRepo
cd MyAppRepo
Create a simple application. For this lab, we'll use a Python Flask app (or any simple app). Create the following files:

app.py:

python
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from CI/CD Lab!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
requirements.txt:

text
Flask==2.3.3
Create a buildspec.yml file at the root (this will be used by CodeBuild):

yaml
version: 0.2

phases:
  install:
    runtime-versions:
      python: 3.9
    commands:
      - echo Installing dependencies...
      - pip install -r requirements.txt
  build:
    commands:
      - echo Build started on `date`
      - echo Building the app...
      # No build step needed for Python, but we can do something
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Packaging the app...
      - mkdir dist
      - cp -r app.py requirements.txt dist/
      - cd dist
      - zip -r ../myapp.zip .
      - cd ..

artifacts:
  files:
    - myapp.zip
  discard-paths: yes

cache:
  paths:
    - '/root/.cache/pip/**/*'
Commit and push:

bash
git add .
git commit -m "Initial commit with buildspec"
git push
Step 2: Create an S3 Bucket for Artifacts
Go to S3 console → Create bucket.

Bucket name: myapp-artifacts-<your-unique-id> (must be globally unique)

Region: same as your CodeCommit repo

Block all public access (keep default)

Create.

Step 3: Create a CodeBuild Project
Go to CodeBuild console → Create build project.

Project name: MyAppBuild

Description: Build my Python app

Source:

Source provider: AWS CodeCommit

Repository: MyAppRepo

Branch: main (or master)

Environment:

Environment image: Managed image

Operating system: Amazon Linux 2

Runtime(s): Standard

Image: aws/codebuild/amazonlinux2-x86_64-standard:5.0 (or latest)

Environment type: Linux

Service role: New service role (auto-generated, will have permissions)

Allow AWS CodeBuild to modify this service role so it can be used with this build project (checked)

Buildspec:

Use a buildspec file (the one in source root)

Artifacts:

Type: Amazon S3

Bucket name: select the bucket you created

Name: (leave blank to use default naming)

Path: (optional, can leave blank)

Namespace type: None

Artifacts packaging: None

Logs:

CloudWatch logs: enable

Group name: /aws/codebuild/MyAppBuild

Stream name: build-log

Create build project.

Step 4: Run the Build
In the CodeBuild project, click Start build (or Start build with overrides to use defaults).

Watch the build logs. It should succeed and produce a myapp.zip artifact in your S3 bucket.

Verify the artifact in S3. Download and inspect: it should contain app.py and requirements.txt.

What you learned: How to set up a CodeCommit repository, write a buildspec, create a CodeBuild project, and store artifacts in S3.
Objective: Understand how stages work, use stage variables to point to different Lambda aliases, and implement canary deployments for safe releases.

Step 1: Create Lambda Aliases
Go to Lambda console → Functions → ItemCrud.

Create a new version: Actions → Publish new version (e.g., Version 1). This captures the current code.

Make a small change to the function (e.g., add a log or change response message) and publish Version 2.

Create aliases:

Aliases tab → Create alias.

Name: DEV

Version: 1

Create.

Create another alias: PROD pointing to Version 2.

Step 2: Update API to Use Stage Variables
In API Gateway console, go to your ItemAPI.

Select any method (e.g., GET on /items) → Integration Request.

Note that the Lambda function is hardcoded. We'll change it to use a stage variable.

Change the Lambda function to: arn:aws:lambda:region:account-id:function:ItemCrud:${stageVariables.alias}

Actually, easier: In the Lambda function field, enter: ItemCrud:${stageVariables.alias} (API Gateway will resolve the full ARN).

But API Gateway needs the full ARN. So we need to set it to something like: arn:aws:lambda:us-east-1:123456789012:function:ItemCrud:${stageVariables.alias}.

To avoid hardcoding the account and region, you can use arn:aws:lambda:${AWS::Region}:${AWS::AccountId}:function:ItemCrud:${stageVariables.alias}? Actually stage variables don't support pseudo parameters. So we'll use a combination: set the Lambda function to ItemCrud:${stageVariables.alias} and ensure the stage variable contains the full ARN? No, API Gateway expects a Lambda function name (with alias) when using proxy. Actually you can just put ItemCrud:${stageVariables.alias} and API Gateway will resolve it to the function ARN. Yes, it's fine.

Let's confirm: In the Lambda function field, you can type ${stageVariables.alias} only? No, you need the base name. Better: Keep the base name as ItemCrud and append :${stageVariables.alias}? Actually the Lambda function ARN format is arn:aws:lambda:region:account:function:function-name:alias. But in the console, when you select Lambda function, you can just enter the function name and alias separated by colon. So you can set it to ItemCrud:${stageVariables.alias}. API Gateway will prefix the ARN automatically. Yes, that works.

So for each method, modify the Integration Request to point to: ItemCrud:${stageVariables.alias}. (You may need to re-enter it and save.)

Also ensure "Use Lambda Proxy integration" is still checked.

Step 3: Configure Stage Variables for Each Stage
Go to Stages → select dev stage.

Stage Variables tab → Add Stage Variable.

Variable: alias

Value: DEV

Save.

Deploy the API again (with same dev stage) to apply changes? Actually stage variables are part of stage configuration, so changes take effect immediately without redeploy. But if you changed the integration, you might need to redeploy. Let's redeploy anyway: Actions → Deploy API to dev (overwrite).

Now the dev stage uses the Lambda alias DEV (Version 1).

Create a new stage prod:

Actions → Deploy API → New Stage → prod.

Add stage variable alias = PROD.

Now you have two stages pointing to different Lambda versions.

Step 4: Test Stages
Test dev stage URL: should show behavior of Version 1.

Test prod stage URL: should show behavior of Version 2.

Step 5: Enable Canary Deployment on Prod Stage
In Stages, select prod.

Go to Canary tab.

Create canary.

Percentage of traffic: 10 (send 10% of requests to the canary)

Stage variable overrides (optional): You can override the alias variable for canary, e.g., set to a new alias PROD_CANARY pointing to a newer version. For simplicity, we'll not override; the canary will use the same alias as the main stage (PROD). But to demonstrate canary, you might create a new Lambda version and alias PROD_CANARY and override. Let's do that:

Publish a new version (Version 3) of Lambda.

Create alias PROD_CANARY pointing to Version 3.

In canary settings, add stage variable override: alias = PROD_CANARY.

Save.

Now 10% of requests to the prod stage will hit the canary (Version 3) while 90% hit the main (Version 2). You can monitor metrics separately.

Step 6: Test Canary
Make several requests to the prod stage endpoint. Check CloudWatch Logs for Lambda (or add a unique identifier in response) to see which version handles the request. You can also enable canary metrics.

What you learned: How to use stage variables to dynamically route to different Lambda aliases, and how to set up canary deployments to test new versions with a percentage of traffic.


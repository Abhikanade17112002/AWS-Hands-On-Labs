Lab 3: Mapping Templates and Request Validation
Objective: Explore non-proxy integrations, use mapping templates to transform requests/responses, and enable request validation.

Step 1: Set up an AWS Service Integration (API Gateway to SQS)
We'll create an API that sends messages to an SQS queue without using Lambda.

Create an SQS queue:

Go to SQS console → Create queue.

Type: Standard

Name: MyQueue

Leave defaults, create.

Note the Queue URL (e.g., https://sqs.region.amazonaws.com/account-id/MyQueue).

In API Gateway, create a new REST API (or reuse existing). Let's create a new one named SQSAPI with Regional endpoint.

Create a resource /send.

Create a POST method on /send.

Integration type: AWS Service

AWS Region: your region

AWS Service: Simple Queue Service (SQS)

HTTP method: POST

Action Type: Use path override (because we'll use Queue URL)

Path override: leave empty? Actually we need to specify the Queue URL. The integration request will be sent to SQS. We'll configure mapping.

Execution role: You need an IAM role that allows API Gateway to call SQS. Create a role with trust policy for apigateway.amazonaws.com and attach AmazonSQSFullAccess (or a policy with sqs:SendMessage). Note the role ARN.

In Integration Request, under HTTP Headers, you may need to add a header Content-Type with value application/x-www-form-urlencoded because SQS expects form data.

Mapping Templates:

When there is no mapping template, the request body is passed as-is. But SQS expects parameters like Action=SendMessage&MessageBody=....

Add a mapping template:

Content-Type: application/json (since client will send JSON)

Choose When there are no templates defined (recommended).

Template body (Velocity):

text
Action=SendMessage&MessageBody=$input.json('$.message')
This takes the incoming JSON like {"message":"hello"} and transforms to Action=SendMessage&MessageBody=hello.

Save.

Deploy API to a stage (e.g., dev). Get invoke URL: https://xxxx/dev/send.

Step 2: Test SQS Integration
Use curl to POST JSON:

bash
curl -X POST https://your-api-url/dev/send \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello SQS"}'
Check the SQS queue in console to see if the message arrived. You may need to poll for messages.

Step 3: Add Request Validation
We want to validate that the incoming request contains a message field and that it's not empty.

In API Gateway, go to your SQSAPI.

Under API settings (left menu), select Models.

Create a model:

Name: MessageModel

Content-Type: application/json

Model schema:

json
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "type": "object",
  "properties": {
    "message": {
      "type": "string",
      "minLength": 1
    }
  },
  "required": ["message"]
}
Go to the POST method on /send.

Method Request:

Request Validator: Select Validate body (or create a new validator: Validate body).

Request Models: Add application/json and select the model MessageModel.

Deploy API again (to same stage) to apply validation.

Step 4: Test Validation
Send a request without message:

bash
curl -X POST https://your-api-url/dev/send \
  -H "Content-Type: application/json" \
  -d '{"wrong":"data"}'
You should receive a 400 Bad Request with validation error details.

Send a correct request: should go through.

What you learned: How to integrate API Gateway directly with AWS services (SQS), use mapping templates to transform requests, and enable request validation using models and validators.
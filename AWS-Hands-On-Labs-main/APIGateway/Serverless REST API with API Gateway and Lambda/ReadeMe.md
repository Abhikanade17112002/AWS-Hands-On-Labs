Lab 1: Build a Serverless REST API with API Gateway and Lambda (Proxy Integration)
Objective: Create a simple CRUD API backed by DynamoDB using Lambda proxy integration. Understand the basics of API Gateway resources, methods, deployments, and stages.

Step 1: Create a DynamoDB Table
Go to DynamoDB console → Create table.

Table name: Items

Partition key: id (String)

Use default settings and create the table.

Step 2: Create an IAM Role for Lambda
Go to IAM console → Roles → Create role.

Trusted entity: AWS service → Lambda.

Attach policies:

AWSLambdaBasicExecutionRole (for CloudWatch logs)

Custom policy or AmazonDynamoDBFullAccess (for simplicity, but in production restrict to specific table)

Role name: LambdaDynamoDBRole. Create.

Step 3: Create a Lambda Function
Go to Lambda console → Create function.

Author from scratch:

Function name: ItemCrud

Runtime: Python 3.9 (or Node.js)

Architecture: x86_64

Permissions: Use existing role → select LambdaDynamoDBRole.

Create function.

Replace the default code with the following (Python):

python
import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Items')

def lambda_handler(event, context):
    method = event['httpMethod']
    path = event['path']
    
    if method == 'GET':
        if path == '/items':
            # Scan all items
            response = table.scan()
            items = response.get('Items', [])
            return {
                'statusCode': 200,
                'body': json.dumps(items)
            }
        elif path.startswith('/items/'):
            # Get single item
            item_id = path.split('/')[-1]
            response = table.get_item(Key={'id': item_id})
            item = response.get('Item', {})
            return {
                'statusCode': 200,
                'body': json.dumps(item)
            }
    
    elif method == 'POST':
        # Create item
        body = json.loads(event['body'])
        item = {
            'id': str(uuid.uuid4()),
            **body
        }
        table.put_item(Item=item)
        return {
            'statusCode': 201,
            'body': json.dumps(item)
        }
    
    elif method == 'PUT':
        # Update item
        item_id = path.split('/')[-1]
        body = json.loads(event['body'])
        # For simplicity, we replace the whole item. In real apps use update expressions.
        item = {'id': item_id, **body}
        table.put_item(Item=item)
        return {
            'statusCode': 200,
            'body': json.dumps(item)
        }
    
    elif method == 'DELETE':
        item_id = path.split('/')[-1]
        table.delete_item(Key={'id': item_id})
        return {
            'statusCode': 204,
            'body': ''
        }
    
    else:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Unsupported method'})
        }
Deploy the function (click Deploy).

Step 4: Create a REST API in API Gateway
Go to API Gateway console → Create API.

Choose REST API (not Private) → Build.

Choose New API:

API name: ItemAPI

Endpoint Type: Regional (for simplicity)

Create API.

Step 5: Create Resources and Methods
Select the root resource (/) → Actions → Create Resource.

Resource name: items

Enable API Gateway CORS? No (we'll do CORS later)

Create Resource.

With /items selected, Actions → Create Method.

Method: GET → checkmark.

Integration type: Lambda Function

Use Lambda Proxy integration: true (important)

Lambda Region: your region

Lambda Function: ItemCrud

Save → OK to add permission.

Repeat for POST on /items with same integration (Lambda proxy).

Create a resource under /items with path parameter:

Select /items → Actions → Create Resource.

Resource name: {id} (the curly braces denote a path parameter)

Create Resource.

With /{id} selected, create GET method (Lambda proxy, same function).

Create PUT method.

Create DELETE method.

Now you have a REST API with CRUD endpoints.

Step 6: Deploy the API to a Stage
Actions → Deploy API.

Deployment stage: [New Stage].

Stage name: dev

Description: Development stage

Deploy.

Note the Invoke URL: e.g., https://xxxxxxxxxx.execute-api.region.amazonaws.com/dev

Step 7: Test the API
Use curl or Postman.

Create an item:

bash
curl -X POST https://your-api-url/dev/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Sample Item","description":"This is a test"}'
Get all items:

bash
curl https://your-api-url/dev/items
Get a specific item (use the id from previous response):

bash
curl https://your-api-url/dev/items/<id>
Update an item:

bash
curl -X PUT https://your-api-url/dev/items/<id> \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Item","description":"Updated"}'
Delete an item:

bash
curl -X DELETE https://your-api-url/dev/items/<id>
What you learned: How to create a REST API with Lambda proxy integration, set up resources and methods, deploy to a stage, and test the endpoints.

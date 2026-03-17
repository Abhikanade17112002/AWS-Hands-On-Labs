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
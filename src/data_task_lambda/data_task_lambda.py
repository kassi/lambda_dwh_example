import boto3
import json
import os


def data_task_lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    body = json.loads(event['body'])
    print("Received body:")
    print(json.dumps(body, indent="|   "))

    payload = body['payload']
    print("Received payload:")
    print(json.dumps(payload, indent="|   "))

    sqs_payload = {
        'data': 'My data'
    }

    # Enqueue to SQS
    sqs = boto3.client('sqs')
    response = sqs.send_message(
        QueueUrl=os.environ['SQS_QUEUE_URL'],
        MessageBody=json.dumps(sqs_payload)
    )
    print("SQS response:")
    print(json.dumps(response))

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
        },
        'body': json.dumps({"message": 'Message enqueued successfully'})
    }

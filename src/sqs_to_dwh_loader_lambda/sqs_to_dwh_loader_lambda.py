#!/usr/bin/env python
# -*- coding: utf-8 -*-

import boto3
import json
import os
import snowflake.connector

from botocore.exceptions import ClientError


def get_secret():
    secret_name = os.environ["SECRET_NAME"]
    region_name = "eu-central-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
        print(get_secret_value_response)
        return json.loads(get_secret_value_response['SecretString'])
    except ClientError as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e


def sqs_to_dwh_loader_lambda_handler(event, context):
    print("Received event:")
    print(json.dumps(event))

    secret = get_secret()
    print("Secret:")
    print(json.dumps(secret))

    # Connect to Snowflake
    with snowflake.connector.connect(
        user=secret['username'],
        password=secret['password'],
        account=secret['account'],
        warehouse=secret['warehouse'],
        database=secret['database'],
        schema=secret['schema'],
        autoCommit=True,
    ) as conn:
        print("Connected to Snowflake: ", conn)

        # SQL-Anweisungen, um das Schema und die Tabelle zu erstellen, falls sie nicht existieren
        create_schema_sql = f"CREATE SCHEMA IF NOT EXISTS {secret['schema']}"
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS my_table_name (
            id INT AUTOINCREMENT,
            date DATETIME,

            PRIMARY KEY (id)
        )
        """

        try:
            print("Creating schema and table if not exists")
            with conn.cursor() as cur:
                cur.execute(create_schema_sql)
                cur.execute(create_table_sql)

                print("Processing records")

                for record in event['Records']:
                    payload = json.loads(record['body'])
                    date = payload.get('date')

                    # Prepare your SQL query
                    query = "INSERT INTO my_table_name (date) VALUES (%s)"

                    try:
                        cur.execute(query,
                                    (date))
                    except Exception as e:
                        # Replace with meaningful id
                        print(f"Error processing date {date}: {e}")
                        raise e

        finally:
            cur.close()
            conn.close()

    return {
        'custom_typeCode': 200,
        'body': json.dumps({"message": 'Data written to Snowflake successfully'})
    }

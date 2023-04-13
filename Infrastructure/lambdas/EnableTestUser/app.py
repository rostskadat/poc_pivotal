import json
import os
import random
import string
import traceback

import boto3

cognito_idp = boto3.client('cognito-idp')
stepfunctions = boto3.client('stepfunctions')

USER_POOL_ID = os.getenv('USER_POOL_ID')
USERNAME = os.getenv('USERNAME')


def lambda_handler(event, context):
    """Enable the Test user in order for the integration test to be launched.

    It also set the password to a random value and pass it along for the Integration test job to continue.
    """
    characters = string.ascii_letters + string.digits + string.punctuation
    random_password = ''.join(random.choice(characters) for i in range(32))
    try:
        cognito_idp.admin_enable_user(
            UserPoolId=USER_POOL_ID,
            Username=USERNAME
        )
        print(f"Enabled Cognito User {USERNAME}.")
        cognito_idp.admin_set_user_password(
            UserPoolId=USER_POOL_ID,
            Username=USERNAME,
            Password=random_password,
            Permanent=True
        )
        print(f"Changed password for Cognito User {USERNAME}.")
        stepfunctions.send_task_success(
            taskToken=event["Token"],
            output=json.dumps({"Payload": {"Password": random_password, "Input": event["Input"]}}))
    except Exception as e:
        traceback.print_exc()
        stepfunctions.send_task_failure(
            taskToken=event["Token"],
            error=type(e).__name__,
            cause=str(e))

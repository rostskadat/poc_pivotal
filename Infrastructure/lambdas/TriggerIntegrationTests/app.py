import json
import os
import traceback

import boto3

stepfunctions = boto3.client('stepfunctions')

STATE_MCHINE_ARN = os.getenv('STATE_MCHINE_ARN')


def lambda_handler(event, _):
    try:
        stepfunctions.start_execution(
            stateMachineArn=STATE_MCHINE_ARN,
            input=json.dumps({
                "Input": {
                    "DeploymentId": event['DeploymentId'],
                    "LifecycleEventHookExecutionId": event['LifecycleEventHookExecutionId']
                }
            }))
        print(f"Started execution of state machine {STATE_MCHINE_ARN}.")
    except:
        traceback.print_exc()

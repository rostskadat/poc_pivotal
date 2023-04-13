import traceback

import boto3

codedeploy = boto3.client('codedeploy')

def lambda_handler(event, _):
    """
    REF: https://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html

    Args:
        event (_type_): _description_
        _ (_type_): _description_
    """
    try:
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=event['DeploymentId'],
            lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
            status="Succeeded")
    except:
        traceback.print_exc()

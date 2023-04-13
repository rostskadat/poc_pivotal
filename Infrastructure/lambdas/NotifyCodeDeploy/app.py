import os
import traceback

import boto3

codedeploy = boto3.client('codedeploy')
cognito_idp = boto3.client('cognito-idp')

USER_POOL_ID = os.getenv('USER_POOL_ID')
USERNAME = os.getenv('USERNAME')


def lambda_handler(event, _):
    """Notify CodeDeploy of Success or Failure of the integration tests.

    It is called by the StepFunctions after the test have been run. \n
    It receive the result as input and then notify CodeDeploy of the result.

    Args:
        event (dict): the structure containing the Status of the integration tests
        _ (_type_): _description_
    """
    try:
        cognito_idp.admin_disable_user(
            UserPoolId=USER_POOL_ID,
            Username=USERNAME
        )
        print(f"Disabled Cognito User {USERNAME}.")
        # In case of failure I get the information a different place
        if 'Cause' in event:
            deployment_id = event['Cause']['Parameters']['DeploymentId']
            lifecycle_event_hook_execution_id = event['Cause']['Parameters']['LifecycleEventHookExecutionId']
            status = "Failed"
        else:
            deployment_id = event['DeploymentId']
            lifecycle_event_hook_execution_id = event['LifecycleEventHookExecutionId']
            status = event['Status']
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status=status)
        print(
            f"Notified CodeDeploy of status '{status}' for deployment '{deployment_id}' ({lifecycle_event_hook_execution_id}).")
    except:
        traceback.print_exc()

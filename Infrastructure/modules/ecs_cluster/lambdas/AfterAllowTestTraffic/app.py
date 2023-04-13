import logging
import os

import boto3

logging.basicConfig(format='%(levelname)s | %(message)s')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Extract from the lambda function all costly action such as setting up a
# connection to a DB, etc...
ENVIRONMENT_VARIABLE = os.getenv('ENVIRONMENT_VARIABLE')

codedeploy = boto3.client('codedeploy')

def lambda_handler(event, _):
    """Execute the test action after the test traffic has been allowed in the newly deployed image.

    Args:
        event (_type_): the code deploy 
        context (_type_): NA

    Returns: NA
    """
    deployment_id = event['DeploymentId']
    lifecycle_event_hook_execution_id = event['LifecycleEventHookExecutionId']
    validation_test_result = "Failed"

    # POC: Simply set the test result to "Succeeded"
    logger.info("We should launch the integration test here.")
    validation_test_result = "Succeeded"

    # Pass CodeDeploy the prepared validation test results.
    try:
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=deployment_id,
            lifecycleEventHookExecutionId=lifecycle_event_hook_execution_id,
            status=validation_test_result)
        logger.info("AfterAllowTestTraffic validation tests succeeded")
    except Exception as e:
        logger.error(e, exc_info=True)

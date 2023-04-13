import logging

import boto3

logging.basicConfig(format='%(levelname)s | %(message)s')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

codedeploy = boto3.client('codedeploy')

def lambda_handler(event, _):
    # if nothing needs to be done we could also skip the hook altogether
    try:
        codedeploy.put_lifecycle_event_hook_execution_status(
            deploymentId=event['DeploymentId'],
            lifecycleEventHookExecutionId=event['LifecycleEventHookExecutionId'],
            status="Succeeded")
        logger.info("AfterAllowTraffic: nothing special to be done")
    except Exception as e:
        logger.error(e, exc_info=True)

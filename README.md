# SOLUNION

## Description

This POC propose an implementation of the different requirements that were expressed during the assesement phase.

## Requirements

1. The application needs to use an Application Load Balancer
2. The application needs to use ECS Fargate
3. The application needs to use a Blue / Green deployment
4. The application needs to use an Integration test to validate the deployment.
5. The application needs to use a Cognito user pool with a IDP connected to the AZURE AD for 
   internal user but also external user.

## TODOs

These are the list of improvments that would be interresting to have

1. Use a custom domain for the API Gateway.
2. Improve failure notifications in case the deployment fails.
3. Add screenshots to the integration tests artifacts.

## Howto build?

1. You first need to create the infrastructure with terraform. In order to do that you will need access to an AWS Account. You should note the different output has you might need them later on.

```shell
?> cd Infrastructure
?> terraform init
?> terraform apply
```
   __BEWARE__: you might have to create the ACM Certificate in the `us-east-1` region manually
   
   __BEWARE__: if it fails on `module.idp.aws_cognito_user_pool_domain.login_domain` with an the error `"Custom domain is not a valid subdomain: Was not able to resolve the root domain, please ensure an A record exists for the root domain."` please wait 10' for the R53 record to propagate and try again

2. You can then start deploying the docker applications. Log into the sandbox ECR repository:

```shell
?> aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.eu-west-1.amazonaws.com
```

3. Build the different docker images and push them. In order to allow the Blue / Green deployment to work, you'll need to make sure that the integration tests image is build and deployed first.

```shell
cd Applications
cd integration-tests-docker
docker build -f Dockerfile.unit_test -t 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/integration_tests:latest . 
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/integration_tests:latest
```

   Then build the `microservice` image (for which no integration tests has been defined)

```shell
cd ../microservice-flask-docker 
docker build -t 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/microservice:latest
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/microservice:latest
```

   And finally the main `webapp` image

```shell
cd ../webapp-flask-docker 
docker build -t 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/webapp:latest src
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/webapp:latest
```

4. You can then open the `<app_url>` to check that the new application has been properly deployed. If you need to login you can create a `aws_cognito_user` and you will then receive a temporary password to login into the `<auth_url>`

# Integration tests

The application runs a series of Selenium integration tests on each deployment. The new deployment will start a Step Function that will execute the following steps:
1. Enable the Cognito User used for integration testing
2. Change its password
3. Start an AWS Batch job that runs a docker container with all the tests
4. Once finished, the Step Function will notify the CodeDeploy deployment of success or failure
5. And finally disable the Cognito User used for integration testing.

## Integration testing locally

You can test you application with the integration tests locally before pushing any new image. This allows you to accelerate the webapp deployment

1. Start the `webapp` locally. Beware that you must setup the environment with the correct variables. There is an example in the file `env.txt`

```shell
cd Applications/webapp-flask-docker
python src/run.py
```

2. Once the `webapp` has been launched, you can execute the integration test on your machine

```shell
cd Applications/integration-tests-docker
BASE_URL=http://localhost:5000
COGNITO_USERNAME=your_username
COGNITO_PASSWORD=your_password
python main_test.py
...

```

# Testing the Microservice.

You need to retrieve the `CLIENT_ID`, the `CLIENT_SECRET`, and have your Cognito `username` and `password`.

Then, you can obtain a token with the `get_cognito_access_token` helper script:

```shell
token=$(python get_cognito_access_token.py --client-id CLIENT_ID --client-secret CLIENT_SECRET --username USERNAME --password PASSWORD | jq -r .AuthenticationResult.AccessToken)

curl https://pwuy53ulth.execute-api.eu-central-1.amazonaws.com/dev/headers -H "Authorization: Bearer ${token}"

```

# DB Synchronization

__Ref__: https://houseofbrick.com/blog/replicating-from-oracle-on-premise-to-oracle-in-aws-rds-using-symmetricds/

## Performance testing

This section explains how to start the perfomance testing of the DB synchronization layer.


1. Write down the `src_replica_endpoint` and `dst_replica_endpoint`
2. Open the AWS SSM session manager for the `symmetricds_instance_id` and execute the following commands:
3. Scrub any remaining configuration. This will drop all the tables that were previously created by SymmetricDS
   
   ```shell
   cd /root
   SRC_HOST=sicyc-dev-src-replica20221215172414176100000002.cv3bqn9qsiga.eu-central-1.rds.amazonaws.com
   DST_HOST=sicyc-dev-dst-replica20221215172201303300000001.cv3bqn9qsiga.eu-central-1.rds.amazonaws.com
   sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$SRC_HOST:1527/SPSOL01 @scrub_symmetricds.sql
   sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$DST_HOST:1527/SPSOL01 @scrub_symmetricds.sql
   rm -rf /opt/symmetric-server-3.14.3/tmp/*
   ```

4. Clean the performance tables. This will truncate the tables used for performance testing
   
   ```shell
   sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$SRC_HOST:1527/SPSOL01 @clean_perf.sql
   sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$DST_HOST:1527/SPSOL01 @clean_perf.sql
   ```

5. Configure SymmetricDS. This will create the necessary tables for synchronizing the different tables and also configure SymmetricDS to synchronize the table used for performance testing
   
   ```shell
   /opt/symmetric-server-3.14.3/bin/symadmin --engine src-000 create-sym-tables
   /opt/symmetric-server-3.14.3/bin/symadmin open-registration --engine src-000 dst 001
   sqlplus OPS\$CREDISEG/OPSCREDISEG_PASSW@$SRC_HOST:1527/SPSOL01 @configure_symmetricds.sql
   ```

6. Start SymmetricDS.
   
   ```shell
   /opt/symmetric-server-3.14.3/bin/sym
   ```

7. Launch the stress test script

   ```shell
   bash stress_test.sh PERF_SMALL
   ```

8. Retrieve the `csv` file with the performance data: `PERF_SMALL.csv`
   
   ```shell
   aws s3 cp ./PERF_SMALL.csv s3://sicyc-dev-symmetric-conf20221222123952004100000001/PERF_SMALL.csv
   ```

The result can then be imported in Excel for further analisis.

# Static analysis 

`tfsec` is used to statically analyze the terraform code

```shell
tfsec Infrastructure
...
  75 passed, 49 potential problem(s) detected.

```


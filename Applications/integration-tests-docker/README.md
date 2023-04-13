# integration-tests-docker

A simple python integration test that runs some Selenium Tests

## Running the example

First create the base image (to not have to re-create it everytime)

```shell
docker build -f Dockerfile.chrome_base -t integration-tests-chrome-base:latest . 
```

Then build the docker image that will launch the python integration test:

```shell
docker build -f Dockerfile.unit_test -t integration-tests:latest -t 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/integration_tests:latest . 
docker run integration-tests:latest 
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/integration_tests:latest
```

## Integration with the AWS BATCH

Please refer to the base `README.md` for an explanation on how the integration with AWS BATCH works
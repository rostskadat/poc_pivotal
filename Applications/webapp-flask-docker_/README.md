# webapp-flask-docker

## Running the example

```shell
docker build -t webapp-flask-docker:latest -t 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/webapp:latest src
docker run -it -e PORT=5000 -p 5000:5000 webapp-flask-docker
docker push 123456789012.dkr.ecr.eu-central-1.amazonaws.com/acme/webapp:latest
```
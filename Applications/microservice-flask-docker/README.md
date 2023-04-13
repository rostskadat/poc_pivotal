# microservice-flask-docker

A really simple microservice.

## Running the example

* Either with docker

```shell
docker build -t microservice-flask-docker:latest src
docker run -it -e PORT=5000 -p 5000:5000 microservice-flask-docker
docker push microservice-flask-docker:latest
```

* Or directly

```shell
pip install -r src/requirements.txt
pytest -v
python.exe src/run.py
```

## References

![linkedin](linkedin.png)
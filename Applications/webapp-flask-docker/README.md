# webapp-flask-docker

A really simple webapp.

## Running the example

* Either with docker

```shell
docker build -t webapp-flask-docker:latest src
docker run -it -e PORT=5000 -p 5000:5000 webapp-flask-docker
docker push webapp-flask-docker:latest
```

* Or directly

```shell
pip install -r src/requirements.txt
pytest -v
python.exe src/run.py
```

## Building the theme

We use [hugo](https://gohugo.io) to build the theme


```shell
hugo new site quickstart
cd quickstart
git init
git submodule add https://github.com/panr/hugo-theme-terminal themes/terminal
git submodule add https://github.com/razonyang/hugo-theme-bootstrap themes/hugo-theme-bootstrap
echo "theme = 'hugo-theme-bootstrap'" >> config.toml
hugo mod npm pack
npm install
hugo server --buildDrafts
hugo server -D
```

## References

![linkedin](linkedin.png)
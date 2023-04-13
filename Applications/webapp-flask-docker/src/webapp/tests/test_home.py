
import os

import pytest
from flask import json
from webapp import create_app
from webapp.config import config_dict


@pytest.fixture
def client():
    DEBUG = (os.getenv('DEBUG', 'False') == 'True')
    get_config_mode = 'Debug' if DEBUG else 'Production'
    app_config = config_dict[get_config_mode.capitalize()]
    app = create_app(app_config)

    with app.test_client() as client:
        with app.app_context():
            print("Initialize test application")
        yield client

    # os.close(db_fd)
    # os.unlink(app.config['DATABASE'])


def test_index(client):
    r = client.get("/")
    assert r.status_code == 302
    assert "/index" in r.get_data(as_text=True)


def test_get_index(client):
    r = client.get("/index")
    assert r.status_code == 200

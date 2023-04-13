# -*- encoding: utf-8 -*-
import os
from importlib import import_module

from apps.authentication.services import cognito_service_factory
from flask import Flask
from flask_awscognito import AWSCognitoAuthentication
from flask_jwt_extended import JWTManager
from flask_login import LoginManager
from flask_session import Session
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
login_manager = LoginManager()
aws_auth = AWSCognitoAuthentication(
    _cognito_service_factory=cognito_service_factory)
jwt = JWTManager()
session = Session()


def configure_database(app):

    @app.before_first_request
    def initialize_datastores():
        try:
            db.create_all()
        except Exception as e:

            print('> Error: DBMS Exception: ' + str(e))

            # fallback to SQLite
            basedir = os.path.abspath(os.path.dirname(__file__))
            app.config['SQLALCHEMY_DATABASE_URI'] = SQLALCHEMY_DATABASE_URI = 'sqlite:///' + \
                os.path.join(basedir, 'db.sqlite3')

            print('> Fallback to SQLite ')
            db.create_all()

    @app.teardown_request
    def shutdown_session(exception=None):
        db.session.remove()


def create_app(config):
    """Initializes the appliation

    REF: 
        https://flask.palletsprojects.com/en/2.2.x/tutorial/factory/
        https://hackersandslackers.com/flask-application-factory/

    Args:
        config (Config): the Config object (cf. config.py)

    Returns:
        Flask: the newly created Flask application
    """
    app = Flask(__name__)
    app.config.from_object(config)

    # Initialize Plugins
    db.init_app(app)
    login_manager.init_app(app)
    aws_auth.init_app(app)
    jwt.init_app(app)
    session.init_app(app)
    # Registering Blueprints
    for module_name in ('authentication', 'home'):
        module = import_module('apps.{}.routes'.format(module_name))
        app.register_blueprint(module.blueprint)

    # Create static asset bundles
    # from .assets import compile_auth_assets, compile_static_assets
    # compile_static_assets(app)
    # compile_auth_assets(app)

    # Create Database Models
    configure_database(app)
    return app

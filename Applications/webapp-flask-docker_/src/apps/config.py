# -*- encoding: utf-8 -*-
"""
Copyright (c) 2019 - present AppSeed.us
"""

import os
import secrets

import redis


class Config(object):

    basedir = os.path.abspath(os.path.dirname(__file__))

    # Assets Management
    ASSETS_ROOT = os.getenv('ASSETS_ROOT', '/static')

    # Set up the App CLIENT_SECRET
    CLIENT_SECRET = os.getenv('CLIENT_SECRET', None)
    if not CLIENT_SECRET:
        CLIENT_SECRET = secrets.token_hex()

    SOCIAL_AUTH_GITHUB = False

    GITHUB_ID = os.getenv('GITHUB_ID')
    GITHUB_SECRET = os.getenv('GITHUB_SECRET')

    # Enable/Disable Github Social Login
    if GITHUB_ID and GITHUB_SECRET:
        SOCIAL_AUTH_GITHUB = True

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    DB_ENGINE = os.getenv('DB_ENGINE', None)
    DB_USERNAME = os.getenv('DB_USERNAME', None)
    DB_PASS = os.getenv('DB_PASS', None)
    DB_HOST = os.getenv('DB_HOST', None)
    DB_PORT = os.getenv('DB_PORT', None)
    DB_NAME = os.getenv('DB_NAME', None)

    USE_SQLITE = True

    # try to set up a Relational DBMS
    if DB_ENGINE and DB_NAME and DB_USERNAME:

        try:

            # Relational DBMS: PSQL, MySql
            SQLALCHEMY_DATABASE_URI = '{}://{}:{}@{}:{}/{}'.format(
                DB_ENGINE,
                DB_USERNAME,
                DB_PASS,
                DB_HOST,
                DB_PORT,
                DB_NAME
            )

            USE_SQLITE = False

        except Exception as e:

            print('> Error: DBMS Exception: ' + str(e))
            print('> Fallback to SQLite ')

    if USE_SQLITE:

        # This will create a file in <app> FOLDER
        SQLALCHEMY_DATABASE_URI = 'sqlite:///' + \
            os.path.join(basedir, 'db.sqlite3')

    AWS_CONSOLE_BASE_URL = "https://eu-central-1.console.aws.amazon.com"
    AWS_DEFAULT_REGION = os.getenv('AWS_DEFAULT_REGION', None)
    AWS_COGNITO_DOMAIN = os.getenv('AWS_COGNITO_DOMAIN', None)
    AWS_COGNITO_USER_POOL_ID = os.getenv('AWS_COGNITO_USER_POOL_ID', None)
    AWS_COGNITO_USER_POOL_CLIENT_ID = os.getenv('AWS_COGNITO_USER_POOL_CLIENT_ID', None)
    AWS_COGNITO_USER_POOL_CLIENT_SECRET = os.getenv('AWS_COGNITO_USER_POOL_CLIENT_SECRET', None)
    AWS_COGNITO_REDIRECT_URL = os.getenv('AWS_COGNITO_REDIRECT_URL', None)
    AWS_APIGW_BASE_URL = os.getenv('AWS_APIGW_BASE_URL', None)


    SECRET_KEY = os.getenv("SECRET_KEY", secrets.token_hex())

    # BEWARE: this initialization must be done before alling the session.init_app
    #   That is the reason why we do it here (in a Config object :()
    # REF: https://flask-session.readthedocs.io/en/latest/#configuration
    if "SESSION_TYPE" in os.environ:
        SESSION_TYPE = os.getenv("SESSION_TYPE")
        REDIS_URI = os.getenv("REDIS_URI")
        SESSION_REDIS = redis.from_url(REDIS_URI)
    else:
        SESSION_PERMANENT = False
        SESSION_TYPE = "filesystem"

    BRANDING = {
        "product_name": "SICYC",
        "vendor_name": "ACME",
        "copyright": "© 2023 ACME"
    }


class ProductionConfig(Config):
    DEBUG = False

    # Security
    SESSION_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_DURATION = 3600


class DebugConfig(Config):
    DEBUG = True


# Load all possible configurations
config_dict = {
    'Production': ProductionConfig,
    'Debug': DebugConfig
}

API_GENERATOR = {
    "books": "Book",
}

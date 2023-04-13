# -*- encoding: utf-8 -*-
import os
import secrets


class Config(object):
    basedir = os.path.abspath(os.path.dirname(__file__))
    SECRET_KEY = os.getenv("SECRET_KEY", secrets.token_hex())
    ASSETS_ROOT = os.getenv('ASSETS_ROOT', '/static')

    BRANDING = {
        "vendor": "example.com",
        "product": "Webapp",
        "copyright": "(c) 2023"
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

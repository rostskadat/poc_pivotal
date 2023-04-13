# -*- encoding: utf-8 -*-
"""
Copyright (c) 2019 - present AppSeed.us
"""
from apps import aws_auth, login_manager
from flask import current_app, session
from flask_login import UserMixin


class CognitoUser(UserMixin):

    id = None
    email = None
    email_verified = False
    access_token = None    

    def __init__(self, **kwargs):
        for property, value in kwargs.items():
            if hasattr(value, '__iter__') and not isinstance(value, str):
                value = value[0]
            setattr(self, property, value)

    def __repr__(self):
        return str(self.email)

@login_manager.user_loader
def user_loader(id):
    """Loads a User from the given id.

    REF: https://flask-login.readthedocs.io/en/latest/#flask_login.LoginManager.user_loader

    Args:
        id (str): the id of the user

    Returns:
        CognitoUser: the cognito user, or None
    """
    try:
        user = _get_user_from_session()
        if not user or user.id != id:
            return None
        return user
    except Exception as e:
        return None


@login_manager.request_loader
def load_user_from_request(request):
    """Loads a User from the request.

    REF: https://flask-login.readthedocs.io/en/latest/#flask_login.LoginManager.request_loader

    Args:
        id (str): the id of the user

    Returns:
        CognitoUser: the cognito user, or None
    """
    try:
        user = _get_user_from_session()
        if not user or user.id != id:
            return None
        return user
    except Exception as e:
        return None


def _get_user_from_session():
    """returns a cognitoUser from the id stored in the session.

    Returns:
        CognitoUser: The Cognito User or None
    """
    # The access_token has been stored by the /cognito_login_callback endpoint.
    access_token = session.get('access_token', None)
    if not access_token:
        current_app.logger.debug(f"access_token not found in the session ...")
        return None
    aws_auth.token_service.verify(access_token)
    access_token_claims = aws_auth.token_service.claims
    if not access_token_claims:
        current_app.logger.debug(
            f"No valid claim found for user with id '{access_token}' ...")
        return None
    id_token = session.get('id_token', None)
    if not id_token:
        current_app.logger.debug(f"id_token not found in the session ...")
        return None
    aws_auth.token_service.verify(id_token)
    id_token_claims = aws_auth.token_service.claims
    if not id_token_claims:
        current_app.logger.debug(
            f"No valid claim found for user with id '{id_token}' ...")
        return None
    return CognitoUser(
        id=id_token_claims["cognito:username"],
        access_token=access_token,
        email=id_token_claims["email"],
        email_verified=id_token_claims["email_verified"]
    )

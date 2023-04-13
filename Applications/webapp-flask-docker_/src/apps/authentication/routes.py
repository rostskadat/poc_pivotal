# -*- encoding: utf-8 -*-
"""
Copyright (c) 2019 - present AppSeed.us
"""


from apps import aws_auth, login_manager
from apps.authentication import blueprint
from flask import (current_app, redirect, render_template, request, session,
                   url_for)
from flask_login import login_user, logout_user

from .models import _get_user_from_session


@blueprint.route('/login', methods=['GET', 'POST'])
def login():
    authorize_url = aws_auth.get_sign_in_url()
    current_app.logger.debug(f"Redirecting to '{authorize_url}' ...")
    return redirect(authorize_url)


@blueprint.route("/cognito_login_callback")
def cognito_login_callback():
    """This method is called by Cognito once the user has been successfully logged in.

    REF: // As per https://docs.aws.amazon.com/cognito/latest/developerguide/token-endpoint.html
    """
    code = request.args.get("code", default=None, type=str)
    current_app.logger.debug(
        f"Obtaining acces token for authorization code '{code}' ...")
    (access_token, id_token) = aws_auth.get_access_token(request.args)
    session['access_token'] = access_token
    session['id_token'] = id_token
    user = _get_user_from_session()
    login_user(user)
    return redirect(url_for('home_blueprint.index'))


@blueprint.route('/logout')
def logout():
    """Logs out the current user.

    Returns:
        response: the redirect response to the login page
    """
    logout_user()
    return redirect(url_for('authentication_blueprint.login'))


@login_manager.unauthorized_handler
def unauthorized_handler():
    return render_template('home/page-403.html'), 403


@blueprint.errorhandler(403)
def access_forbidden(error):
    return render_template('home/page-403.html'), 403


@blueprint.errorhandler(404)
def not_found_error(error):
    return render_template('home/page-404.html'), 404


@blueprint.errorhandler(500)
def internal_error(error):
    return render_template('home/page-500.html'), 500

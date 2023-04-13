# -*- encoding: utf-8 -*-
"""
Copyright (c) 2019 - present AppSeed.us
"""

import requests
from apps.config import API_GENERATOR
from apps.home import blueprint
from flask import current_app, redirect, render_template, request, url_for
from flask_login import current_user, login_required
from jinja2 import TemplateNotFound


@blueprint.route('/health')
def health():
    """Returns a health check string.

    Returns:
        string: a dummy content used by the health check.
    """
    return "OK"


@blueprint.route('/headers')
def list_headers():
    """Returns a json with the request headers.

    Mainly used for debugging.

    Returns:
        json: the request headers
    """
    return {k: v for k, v in request.headers}


@blueprint.route('/')
def route_default():
    if current_user.is_authenticated:
        return redirect(url_for('home_blueprint.index'))
    else:
        return redirect(url_for('authentication_blueprint.login'))


@blueprint.route('/index')
@login_required
def index():
    return render_template('home/index.html', segment='index', API_GENERATOR=len(API_GENERATOR))


@blueprint.route('/call_apigw')
@login_required
def call_apigw():
    """Dummy WS that calls the APIGW in the background.

    It uses the credentials of the currently logged in user in order to connect to the APIGW.
    It could in fact any other credentials (github, etc.).

    Returns:
        json: the response from the backend
    """
    access_token = current_user.access_token
    apigw_url = current_app.config['AWS_APIGW_BASE_URL'] + "/headers"
    response = requests.post(apigw_url, headers={'Authorization': f"Bearer {access_token}"})
    return response.json()


@blueprint.route('/<template>')
@login_required
def route_template(template):
    try:
        if not template.endswith('.html'):
            template += '.html'
        # Detect the current page
        segment = _get_segment(request)
        # Serve the file (if exists) from app/templates/home/FILE.html
        return render_template("home/" + template,
                               segment=segment,
                               access_token=current_user.access_token,
                               microservice_url=current_app.config["AWS_APIGW_BASE_URL"]
                               )
    except TemplateNotFound:
        return render_template('home/page-404.html'), 404
    except Exception as e:
        current_app.logger.error(str(e))
        return render_template('home/page-500.html'), 500


def _get_segment(request):
    """Extract current page name from request"""
    try:
        segment = request.path.split('/')[-1]
        if segment == '':
            segment = 'index'
        return segment
    except:
        return None

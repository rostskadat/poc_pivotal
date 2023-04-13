# -*- encoding: utf-8 -*-
from flask import render_template, request
from flask_login import login_required
from jinja2 import TemplateNotFound
from webapp.home import blueprint


@blueprint.route('/index')
@login_required
def index():
    return render_template('home/index.html')


@blueprint.route('/<template>')
@login_required
def route_template(template):
    try:
        if not template.endswith('.html'):
            template += '.html'
        return render_template("home/" + template)
    except TemplateNotFound:
        return render_template('home/page-404.html'), 404
    except:
        return render_template('home/page-500.html'), 500

# -*- encoding: utf-8 -*-

import flask
from flask import redirect, render_template, url_for
from flask_login import UserMixin, login_user, logout_user
from webapp import login_manager
from webapp.authentication import blueprint

users = {'name@example.com': {'password': '1234'}}


class User(UserMixin):
    pass


@login_manager.user_loader
def user_loader(email):
    if email not in users:
        return

    user = User()
    user.id = email
    return user


@login_manager.request_loader
def request_loader(request):
    email = request.form.get('email')
    if email not in users:
        return

    user = User()
    user.id = email
    return user


@blueprint.route('/login', methods=['GET', 'POST'])
def login():
    if flask.request.method == 'GET':
        return render_template("authentication/login.html")

    email = flask.request.form['email']
    if email in users and flask.request.form['password'] == users[email]['password']:
        user = User()
        user.id = email
        login_user(user)
        return flask.redirect(flask.url_for('home_blueprint.index'))

    return 'Bad login', 401


@blueprint.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('authentication_blueprint.login'))


@login_manager.unauthorized_handler
def unauthorized_handler():
    return render_template('authentication/page-403.html'), 403

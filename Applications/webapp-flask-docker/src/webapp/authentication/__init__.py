# -*- encoding: utf-8 -*-
from flask import Blueprint

blueprint = Blueprint('authentication_blueprint',
                      __name__,
                      template_folder='templates',
                      url_prefix='')

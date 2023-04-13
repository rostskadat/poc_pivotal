# -*- encoding: utf-8 -*-
import os
from sys import exit

from api_generator.commands import gen_api
from apps import create_app, db
from apps.config import config_dict
from flask_migrate import Migrate
from flask_minify import Minify

# WARNING: Don't run with debug turned on in production!
DEBUG = (os.getenv('DEBUG', 'False') == 'True')

# The configuration
get_config_mode = 'Debug' if DEBUG else 'Production'

try:

    # Load the configuration using the default values
    app_config = config_dict[get_config_mode.capitalize()]

except KeyError:
    exit('Error: Invalid <config_mode>. Expected values [Debug, Production] ')

app = create_app(app_config)
Migrate(app, db)


if not DEBUG:
    Minify(app=app, html=True, js=False, cssless=False)

if DEBUG:
    app.logger.info('DEBUG            = ' + str(DEBUG))
    app.logger.info('Page Compression = ' + str(False if DEBUG else True))
    app.logger.info('DBMS             = ' + app_config.SQLALCHEMY_DATABASE_URI)
    app.logger.info('ASSETS_ROOT      = ' + app_config.ASSETS_ROOT)
    app.config['TEMPLATES_AUTO_RELOAD'] = True

for command in [gen_api, ]:
    app.cli.add_command(command)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(port=port)

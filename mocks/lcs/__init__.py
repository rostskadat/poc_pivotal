import logging
import xml.etree.ElementTree as ET
from os.path import dirname

import requests
import xmltodict
from jinja2 import Environment, FileSystemLoader

SERVICE_URL = "http://SES000A204221/Pivotal/Services/PivotalServices.aspx"
LCS_SERVER = "SES000A204221"
SYSTEM_NAME = "Mapfre"

def _render_template(template_name, args):
    env = Environment(loader=FileSystemLoader(dirname(__file__)))
    template = env.get_template(template_name)
    return template.render(args)

def _send_command(username, password, xml_command):
    url = "{SERVICE_URL}?server={LCS_SERVER}".format(**globals())
    headers = {
        'useraAgent': 'Mozilla/4.0',
        'content-type': 'text/xml; charset=utf-8',
        'content-length': str(len(xml_command))
    }
    return requests.post(url, data=xml_command, headers=headers, auth=(username, password))

def _execute_command(username, password, template, args):
    xml_command = _render_template(template, args)
    logging.debug(xml_command)
    response = _send_command(username, password, xml_command)
    logging.debug(response)
    return xmltodict.parse(response.text)

def get_user_id(username, password, context):
    context['system_name'] = SYSTEM_NAME
    return _execute_command(username, password, 'get_user_id.jinja2.xml', context)

def get_form_data(username, password, context):
    context['system_name'] = SYSTEM_NAME
    return _execute_command(username, password, 'get_form_data.jinja2.xml', context)

def execute_asr(username, password, context):
    context['system_name'] = SYSTEM_NAME
    return _execute_command(username, password, 'execute_asr.jinja2.xml', context)

def execute_script(username, password, context):
    context['system_name'] = SYSTEM_NAME
    return _execute_command(username, password, 'execute_script.jinja2.xml', context)

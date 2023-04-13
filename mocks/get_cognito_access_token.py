"""
Produce the proper SECRET_HASH to be able to call APIGW with curl

Reference: https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash

SYNOPSIS:

get_cognito_access_token --username USERNAME --password PASSWORD --client-id CLIENT_ID --client-secret CLIENT_SECRET

"""

import base64
import hashlib
import hmac
import json
import logging
import sys
from argparse import ArgumentParser, RawTextHelpFormatter

import requests

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s | %(levelname)-8s | %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger()


def get_secret_hash(args):
    message = bytes(args.username+args.client_id, 'utf-8')
    key = bytes(args.client_secret, 'utf-8')
    secret_hash = base64.b64encode(
        hmac.new(key, message, digestmod=hashlib.sha256).digest()).decode()
    logger.debug(f"SECRET_HASH={secret_hash}")
    return secret_hash


def get_access_token(args):
    secret_hash = get_secret_hash(args)
    headers = {'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
               'Content-Type': 'application/x-amz-json-1.1'}
    payload = {"AuthFlow": "USER_PASSWORD_AUTH",
               "ClientId": args.client_id,
               "AuthParameters": {"USERNAME": args.username,
                                  "PASSWORD": args.password,
                                  "SECRET_HASH": secret_hash
                                  }
               }
    logger.debug (f"url={args.cognito_idp_url}")
    logger.debug (f"headers={headers}")
    logger.debug (f"payload={payload}")
    r = requests.post(args.cognito_idp_url, headers=headers, json=payload)
    if r.status_code == 200:
        print(json.dumps(r.json(), indent=4))
    else:
        logger.error(r.content)
    return 0


def parse_command_line():
    parser = ArgumentParser(prog='call_pivotal_endpoint',
                            description=__doc__, formatter_class=RawTextHelpFormatter)
    parser.add_argument(
        '--debug', action="store_true", help='Run the program in debug', required=False, default=False)
    parser.add_argument(
        '--username', help='The username', required=True)
    parser.add_argument(
        '--password', help='The password', required=True)
    parser.add_argument(
        '--client-id', help='The client id', required=True)
    parser.add_argument(
        '--client-secret', help='The client secret', required=True)
    parser.add_argument(
        '--cognito-idp-url', help='The Cognito IDP URL', required=False, default="https://cognito-idp.eu-central-1.amazonaws.com")
    parser.set_defaults(func=get_access_token)
    return parser.parse_args()


def main():
    args = parse_command_line()
    try:
        if args.debug:
            logger.setLevel(logging.DEBUG)
            logger.propagate = True
        return args.func(args)
    except Exception as e:
        logging.error(e)
        return 1


if __name__ == '__main__':
    sys.exit(main())

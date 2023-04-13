"""
Produce the proper SECRET_HASH to be able to call APIGW with curl

Reference: 
- https://github.com/awslabs/aws-support-tools/blob/master/Cognito/decode-verify-jwt/decode-verify-jwt.py
- https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html
- https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html#cognito-user-pools-computing-secret-hash

SYNOPSIS:

verify_jwt_token --jwt-token "eyJraWQiOiJcL1JSSl..." --client-secret CLIENT_SECRET

"""

import json
import logging
import sys
import time
import urllib.request
from argparse import ArgumentParser, RawTextHelpFormatter

from jose import jwk, jwt
from jose.utils import base64url_decode

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s | %(levelname)-8s | %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger()


def _get_keys(args):
    keys_url = f"{args.cognito_idp_url}/{args.cognito_pool_id}/.well-known/jwks.json"
    with urllib.request.urlopen(keys_url) as f:
        response = f.read()
    return json.loads(response.decode('utf-8'))['keys']


def verify_token(args):
    keys = _get_keys(args)
    token = args.jwt_token
    # get the kid from the headers prior to verification
    headers = jwt.get_unverified_headers(token)
    kid = headers['kid']
    # search for the kid in the downloaded public keys
    key_index = -1
    for i in range(len(keys)):
        if kid == keys[i]['kid']:
            key_index = i
            break
    if key_index == -1:
        logger.error('Public key not found in jwks.json')
        return 1
    logger.debug(f"Found Key ID {kid} in downloaded public keys")
    # construct the public key
    public_key = jwk.construct(keys[key_index])
    # get the last two sections of the token,
    # message and signature (encoded in base64)
    message, encoded_signature = str(token).rsplit('.', 1)
    # decode the signature
    decoded_signature = base64url_decode(encoded_signature.encode('utf-8'))
    # verify the signature
    if not public_key.verify(message.encode("utf8"), decoded_signature):
        logger.error('Signature verification failed')
        return 1
    logger.debug('Signature successfully verified')
    # since we passed the verification, we can now safely
    # use the unverified claims
    claims = jwt.get_unverified_claims(token)
    # additionally we can verify the token expiration
    if time.time() > claims['exp']:
        logger.error('Token is expired')
        return 1
    # and the Audience  (use claims['client_id'] if verifying an access token)
    if 'aud' in claims and claims['aud'] != args.client_id:
        logger.error(
            f"Token was issued for {claims['aud']}, not {args.client_id}")
        return 1
    # now we can use the claims
    if claims:
        logger.info(claims)
    else:
        logger.warning("No claims found!")
    return 0


def parse_command_line():
    parser = ArgumentParser(prog='call_pivotal_endpoint',
                            description=__doc__, formatter_class=RawTextHelpFormatter)
    parser.add_argument(
        '--debug', action="store_true", help='Run the program in debug', required=False, default=False)
    parser.add_argument(
        '--jwt-token', help='The JWT Token to verify', required=True)
    parser.add_argument(
        '--client-id', help='The client id', required=True)
    parser.add_argument(
        '--client-secret', help='The client secret', required=False, default=None)
    parser.add_argument(
        '--cognito-pool-id', help='The Cognito pool ID', required=True)
    parser.add_argument(
        '--cognito-idp-url', help='The Cognito IDP URL', required=False, default="https://cognito-idp.eu-central-1.amazonaws.com")
    parser.set_defaults(func=verify_token)
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

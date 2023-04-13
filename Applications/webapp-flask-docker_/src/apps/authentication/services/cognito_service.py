from base64 import b64encode

import requests
from flask_awscognito.exceptions import FlaskAWSCognitoError
from flask_awscognito.services.cognito_service import CognitoService


class ExtendedCognitoService(CognitoService):
    """Extend the default CognitoService. 

    It is necessary to also get the id_token, as this is what we use to get the
    information from the user. An alternative would be to query the Cognito 
    Userpool directly using the get_user method (as per https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/cognito-idp.html#CognitoIdentityProvider.Client.get_user)

    Args:
        CognitoService (CognitoService): The base CognitoService
    """

    def __init__(self, *args):
        super().__init__(*args)

    def exchange_code_for_token(self, code, requests_client=None):
        token_url = f"{self.domain}/oauth2/token"
        data = {
            "code": code,
            "redirect_uri": self.redirect_url,
            "client_id": self.user_pool_client_id,
            "grant_type": "authorization_code",
        }
        headers = {}
        if self.user_pool_client_secret:
            secret = b64encode(
                f"{self.user_pool_client_id}:{self.user_pool_client_secret}".encode(
                    "utf-8"
                )
            ).decode("utf-8")
            headers = {"Authorization": f"Basic {secret}"}
        try:
            if not requests_client:
                requests_client = requests.post
            response = requests_client(token_url, data=data, headers=headers)
            response_json = response.json()
        except requests.exceptions.RequestException as e:
            raise FlaskAWSCognitoError(str(e)) from e
        if "access_token" not in response_json:
            raise FlaskAWSCognitoError(
                f"no access token returned for code {response_json}"
            )
        return (response_json["access_token"], response_json["id_token"])

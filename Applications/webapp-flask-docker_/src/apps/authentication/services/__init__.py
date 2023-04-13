from .cognito_service import ExtendedCognitoService


def cognito_service_factory(
    user_pool_id,
    user_pool_client_id,
    user_pool_client_secret,
    redirect_url,
    region,
    domain,
):
    return ExtendedCognitoService(
        user_pool_id,
        user_pool_client_id,
        user_pool_client_secret,
        redirect_url,
        region,
        domain,
    )

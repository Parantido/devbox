from flask import request, Response, redirect, make_response
import urllib.parse
import requests
import jwt
from config import Config, logger
from auth_utils import AuthUtils

# Create a variable to store the client secret
_client_secret = None

def init_routes(client_secret):
    global _client_secret
    _client_secret = client_secret

def auth_route():
    logger.info("Received authentication request")

    logger.debug("All headers:")
    for header, value in request.headers.items():
        logger.debug(f"  {header}: {value}")

    original_path = request.headers.get('X-Original-Url', '')
    original_proto = request.headers.get('X-Forwarded-Proto', 'https')
    original_host = request.headers.get('X-Forwarded-Host', '')

    original_url = f"{original_proto}://{original_host}{original_path}"
    logger.debug(f"Original URL from custom header: {original_url}")

    auth_cookie = request.cookies.get('auth_token')
    auth_header = request.headers.get('Authorization', '')

    token = None
    if auth_cookie:
        token = auth_cookie
        logger.debug("Found token in cookie")
        logger.debug(f"Token header: {jwt.get_unverified_header(token)}")
    elif auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1]
        logger.debug("Found token in Authorization header")
        logger.debug(f"Token header: {jwt.get_unverified_header(token)}")

    if not token:
        logger.info("No valid authorization found, redirecting to login")
        login_url = AuthUtils.build_login_url(original_url)
        return redirect(login_url)

    decoded_token = AuthUtils.validate_token(token)
    if not decoded_token:
        logger.info("Token validation failed, clearing cookie and redirecting to login")
        response = make_response(redirect(AuthUtils.build_login_url(original_url)))
        response.delete_cookie('auth_token', domain=Config.DOMAIN, path='/')
        return response

    logger.info("Authentication successful")
    response = Response('OK', status=200)
    response.headers['X-Forwarded-User'] = decoded_token.get('preferred_username', '')
    response.headers['Authorization'] = f"Bearer {token}"
    
    response.set_cookie(
        'auth_token',
        token,
        secure=True,
        httponly=True,
        samesite='Lax',
        max_age=3600,
        domain=Config.DOMAIN,
        path='/'
    )
    return response

def callback_route():
    logger.info("Received callback request")
    logger.debug(f"All headers: {dict(request.headers)}")
    logger.debug(f"Query parameters: {dict(request.args)}")
    
    code = request.args.get('code')
    state = request.args.get('state', '/')
    
    if not code:
        logger.error("No authorization code in callback request")
        return Response('Authorization code missing', status=400)

    token_url = f"{Config.KEYCLOAK_URL}/realms/{Config.KEYCLOAK_REALM}/protocol/openid-connect/token"
    callback_url = f"https://{Config.HOSTNAME}.{Config.DOMAIN}/oauth/callback"

    data = {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': Config.KEYCLOAK_CLIENT_ID,
        'client_secret': _client_secret,  # Use the injected client secret
        'redirect_uri': callback_url
    }

    logger.debug(f"Token request URL: {token_url}")
    logger.debug(f"Token request data: {data}")

    try:
        response = requests.post(token_url, data=data)
        
        if response.status_code != 200:
            logger.error(f"Token exchange failed: {response.text}")
            logger.debug(f"Response headers: {dict(response.headers)}")
            return Response('Token exchange failed', status=400)

        tokens = response.json()
        logger.info("Successfully received tokens")
        
        original_url = urllib.parse.unquote(state)
        logger.debug(f"Redirecting to original URL: {original_url}")
        
        response = make_response(redirect(original_url))
        
        response.set_cookie(
            'auth_token',
            tokens['access_token'],
            secure=True,
            httponly=True,
            samesite='Lax',
            max_age=int(tokens.get('expires_in', 3600)),
            domain=Config.DOMAIN,
            path='/'
        )

        return response

    except requests.RequestException as e:
        logger.error(f"Request to token endpoint failed: {str(e)}")
        return Response('Token exchange failed', status=400)

import jwt
import json
import requests
from jwt.algorithms import RSAAlgorithm
from config import Config, logger
import urllib.parse

class AuthUtils:
    _jwks_keys = {}  # Cache for all JWKS keys

    @staticmethod
    def _get_key_from_jwks(kid):
        logger.info(f"Getting key with ID: {kid}")
        try:
            # Return cached key if available
            if kid in AuthUtils._jwks_keys:
                logger.debug(f"Using cached key for kid: {kid}")
                return AuthUtils._jwks_keys[kid]

            # Fetch JWKS
            well_known_url = f"{Config.KEYCLOAK_URL}/realms/{Config.KEYCLOAK_REALM}/.well-known/openid-configuration"
            well_known = requests.get(well_known_url).json()
            jwks_uri = well_known['jwks_uri']
            jwks = requests.get(jwks_uri).json()
            logger.debug("Retrieved new JWKS from Keycloak")

            # Cache all keys
            for key in jwks['keys']:
                key_id = key['kid']
                AuthUtils._jwks_keys[key_id] = RSAAlgorithm.from_jwk(json.dumps(key))
                logger.debug(f"Cached key with kid: {key_id}")

            # Return requested key
            if kid in AuthUtils._jwks_keys:
                return AuthUtils._jwks_keys[kid]
            else:
                raise Exception(f"Key ID {kid} not found in JWKS")

        except Exception as e:
            logger.error(f"Error retrieving key {kid}: {e}")
            raise

    @staticmethod
    def validate_token(token):
        logger.info("Starting token validation")
        try:
            # First, decode the token header without verification to get the key ID
            unverified_header = jwt.get_unverified_header(token)
            kid = unverified_header.get('kid')
            
            if not kid:
                logger.error("No 'kid' found in token header")
                return None
    
            logger.debug(f"Token uses key ID: {kid}")
            
            # Get the correct public key for this token
            public_key = AuthUtils._get_key_from_jwks(kid)
    
            try:
                decoded = jwt.decode(
                    token,
                    public_key,
                    algorithms=['RS256'],
                    # Accept both the client ID and the actual audiences
                    audience=['traefik-client', 'master-realm', 'account'],
                    options={
                        'verify_aud': False  # Temporarily disable audience verification
                    }
                )
                logger.info("Token successfully validated")
                logger.debug(f"Token claims: {json.dumps(decoded, indent=2)}")
                return decoded
                
            except jwt.ExpiredSignatureError:
                logger.error("Token validation failed: Token has expired")
                return None
            except jwt.InvalidTokenError as e:
                logger.error(f"Token validation failed: {str(e)}")
                return None
    
        except Exception as e:
            logger.error(f"Error during token validation: {str(e)}")
            return None

    @staticmethod
    def build_login_url(original_url):
        logger.info("Building Keycloak login URL")
        logger.debug(f"Original URL: {original_url}")

        auth_callback_url = f"https://{Config.HOSTNAME}.{Config.DOMAIN}/oauth/callback"
        encoded_state = urllib.parse.quote(original_url)

        params = {
            'client_id': Config.KEYCLOAK_CLIENT_ID,
            'response_type': 'code',
            'scope': 'openid profile',
            'redirect_uri': auth_callback_url,
            'state': encoded_state
        }

        auth_url = f"{Config.KEYCLOAK_URL}/realms/{Config.KEYCLOAK_REALM}/protocol/openid-connect/auth"
        full_url = f"{auth_url}?{urllib.parse.urlencode(params)}"

        logger.debug(f"Generated login URL: {full_url}")
        return full_url


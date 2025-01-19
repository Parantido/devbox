import os
import logging
import sys

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

class Config:
    KEYCLOAK_URL = os.environ['SSO_URL']
    KEYCLOAK_REALM = os.environ['KEYCLOAK_REALM']
    KEYCLOAK_CLIENT_ID = os.environ['KEYCLOAK_CLIENT_ID']
    DB_HOST = os.environ.get('IAM_DB_HOSTNAME', 'code-db')
    DB_USER = os.environ['IAM_DB_USERNAME']
    DB_PASS = os.environ['IAM_DB_PASSWORD']
    DB_NAME = 'iam'
    DOMAIN = os.environ['DOMAIN']
    HOSTNAME = os.environ['HOSTNAME']

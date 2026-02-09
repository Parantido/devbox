"""
Authorization Service for Traefik ForwardAuth

This service works in conjunction with OAuth2 Proxy to provide:
1. Authentication via GitHub OAuth (delegated to OAuth2 Proxy)
2. Authorization via YAML-based access control rules
"""

import os
import logging
import fnmatch
from urllib.parse import urlencode, quote, urlparse

import yaml
import requests
from flask import Flask, request, Response, redirect

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration
CONFIG_PATH = os.environ.get('AUTHZ_CONFIG_PATH', '/config/authz.yaml')
OAUTH2_PROXY_URL = os.environ.get('OAUTH2_PROXY_URL', 'http://oauth2-proxy:4180')
OAUTH2_PROXY_USERINFO = f"{OAUTH2_PROXY_URL}/oauth2/userinfo"

# Cache config with modification time check
_config_cache = None
_config_mtime = 0


def load_config():
    """Load authorization config from YAML file, with caching."""
    global _config_cache, _config_mtime

    try:
        current_mtime = os.path.getmtime(CONFIG_PATH)
        if _config_cache is None or current_mtime > _config_mtime:
            with open(CONFIG_PATH, 'r') as f:
                _config_cache = yaml.safe_load(f)
                _config_mtime = current_mtime
                logger.info(f"Loaded authorization config from {CONFIG_PATH}")
        return _config_cache
    except Exception as e:
        logger.error(f"Error loading config: {e}")
        return {'default_policy': 'deny', 'resources': {}, 'groups': {}}


def get_user_from_oauth2_proxy(cookies):
    """
    Validate session with OAuth2 Proxy and get user information.

    Returns dict with user info or None if not authenticated.
    """
    try:
        # Forward the session cookie to OAuth2 Proxy
        resp = requests.get(
            OAUTH2_PROXY_USERINFO,
            cookies=cookies,
            headers={'Accept': 'application/json'},
            timeout=5
        )

        if resp.status_code == 200:
            userinfo = resp.json()
            logger.debug(f"OAuth2 Proxy userinfo: {userinfo}")
            return userinfo
        else:
            logger.debug(f"OAuth2 Proxy returned {resp.status_code}")
            return None

    except requests.exceptions.RequestException as e:
        logger.error(f"Error contacting OAuth2 Proxy: {e}")
        return None


def expand_groups(config, group_names):
    """Expand group names to list of users."""
    users = set()
    groups = config.get('groups', {})

    for group_name in group_names:
        if group_name in groups:
            group_users = groups[group_name]
            if isinstance(group_users, list):
                users.update(group_users)
            elif isinstance(group_users, dict):
                # Support nested group definition with 'users' key
                users.update(group_users.get('users', []))

    return users


def find_matching_resource(path, resources):
    """
    Find the most specific matching resource for a path.
    Returns (resource_path, rules) or (None, None).
    """
    matches = []

    for resource_path, rules in resources.items():
        # Handle different matching patterns
        if resource_path.endswith('*'):
            # Wildcard match: /code/danilo/* matches /code/danilo/anything
            base_path = resource_path.rstrip('*').rstrip('/')
            if path == base_path or path.startswith(base_path + '/'):
                matches.append((len(base_path), resource_path, rules))
        elif path == resource_path or path.startswith(resource_path + '/'):
            # Exact prefix match
            matches.append((len(resource_path), resource_path, rules))
        elif fnmatch.fnmatch(path, resource_path):
            # Glob pattern match
            matches.append((len(resource_path), resource_path, rules))

    if matches:
        # Return the most specific match (longest path)
        matches.sort(key=lambda x: x[0], reverse=True)
        return matches[0][1], matches[0][2]

    return None, None


def is_user_authorized(username, path, config):
    """
    Check if user is authorized to access the path.

    Returns tuple: (authorized: bool, reason: str)
    """
    resources = config.get('resources', {})

    # Find matching resource
    resource_path, rules = find_matching_resource(path, resources)

    if rules is None:
        # No matching resource - use default policy
        default_policy = config.get('default_policy', 'deny')
        if default_policy == 'allow':
            return True, "default policy: allow"
        else:
            return False, "no matching resource, default policy: deny"

    # Build allowed users set
    allowed_users = set(rules.get('users', []))

    # Expand groups
    allowed_groups = rules.get('groups', [])
    allowed_users.update(expand_groups(config, allowed_groups))

    # Check if user is in allowed set
    if username in allowed_users:
        return True, f"user authorized for {resource_path}"

    # Check if resource allows all authenticated users
    if rules.get('authenticated', False):
        return True, f"resource {resource_path} allows all authenticated users"

    return False, f"user '{username}' not authorized for {resource_path}"


@app.route('/auth')
def auth():
    """
    ForwardAuth endpoint for Traefik.

    Expected headers from Traefik:
    - X-Forwarded-Uri: Original request URI
    - X-Forwarded-Host: Original host
    - X-Forwarded-Proto: Original protocol (http/https)
    - X-Forwarded-Method: Original HTTP method
    """
    config = load_config()

    # Get original request info from Traefik headers
    original_uri = request.headers.get('X-Forwarded-Uri', '/')
    original_host = request.headers.get('X-Forwarded-Host', '')
    original_proto = request.headers.get('X-Forwarded-Proto', 'https')
    original_method = request.headers.get('X-Forwarded-Method', 'GET')

    logger.info(f"Auth request: {original_method} {original_proto}://{original_host}{original_uri}")

    # Forward cookies to OAuth2 Proxy for session validation
    cookies = {key: value for key, value in request.cookies.items()}

    # Validate session with OAuth2 Proxy
    userinfo = get_user_from_oauth2_proxy(cookies)

    if not userinfo:
        # Not authenticated - redirect to OAuth2 Proxy login
        # The 'rd' parameter tells OAuth2 Proxy where to redirect after login
        redirect_url = f"{original_proto}://{original_host}{original_uri}"
        login_url = f"{original_proto}://{original_host}/oauth2/start?rd={quote(redirect_url)}"

        logger.info(f"User not authenticated, redirecting to login")
        return redirect(login_url, code=302)

    # Extract username from OAuth2 Proxy response
    # GitHub provider uses 'user' field for username
    username = userinfo.get('user') or userinfo.get('preferredUsername', '')
    email = userinfo.get('email', '')

    logger.info(f"User authenticated: {username} ({email})")

    # Strip query string before matching resources
    auth_path = urlparse(original_uri).path

    # Check authorization
    authorized, reason = is_user_authorized(username, auth_path, config)

    if authorized:
        logger.info(f"Access granted: {username} -> {original_uri} ({reason})")

        # Return 200 with user info headers
        response = Response(status=200)
        response.headers['X-Auth-User'] = username
        response.headers['X-Auth-Email'] = email
        return response
    else:
        logger.warning(f"Access denied: {username} -> {original_uri} ({reason})")

        return Response(
            f"Access Denied\n\nUser '{username}' is not authorized to access '{original_uri}'.\n\nReason: {reason}",
            status=403,
            content_type='text/plain'
        )


@app.route('/health')
def health():
    """Health check endpoint."""
    return Response('OK', status=200)


@app.route('/')
def index():
    """Root endpoint - returns service info."""
    return Response(
        'Authorization Service\n\nEndpoints:\n  /auth - ForwardAuth endpoint\n  /health - Health check\n',
        status=200,
        content_type='text/plain'
    )


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)

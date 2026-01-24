# Authorization Service

A lightweight Python/Flask service that provides fine-grained authorization for Traefik's ForwardAuth middleware.

## Overview

This service works in conjunction with OAuth2 Proxy to provide:
1. **Authentication** - Delegated to OAuth2 Proxy (GitHub OAuth)
2. **Authorization** - YAML-based access control rules

## How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Traefik     │────▶│  authz-service  │────▶│  OAuth2 Proxy   │
│  ForwardAuth    │     │   /auth         │     │  /userinfo      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │   authz.yaml    │
                        │  (permissions)  │
                        └─────────────────┘
```

1. Traefik sends a ForwardAuth request to `/auth`
2. The service extracts session cookies from the request
3. Validates the session by calling OAuth2 Proxy's `/oauth2/userinfo`
4. If not authenticated → Returns redirect to OAuth2 login
5. If authenticated → Checks `authz.yaml` for permission
6. Returns `200` (allow) or `403` (deny)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTHZ_CONFIG_PATH` | `/config/authz.yaml` | Path to authorization config |
| `OAUTH2_PROXY_URL` | `http://oauth2-proxy:4180` | OAuth2 Proxy internal URL |

### Authorization Config (authz.yaml)

```yaml
# Default policy when no resource matches
default_policy: deny  # or 'allow'

# User groups
groups:
  admins:
    - admin-user
  developers:
    - dev1
    - dev2

# Resource access rules
resources:
  /code/danilo:
    users:
      - danilo

  /shared:
    groups:
      - developers

  /public:
    authenticated: true  # Any logged-in user
```

### Path Matching

Paths are matched using prefix matching with support for wildcards:

| Pattern | Matches |
|---------|---------|
| `/code/danilo` | `/code/danilo`, `/code/danilo/foo`, `/code/danilo/foo/bar` |
| `/code/danilo/*` | Same as above (explicit wildcard) |
| `/api/*/users` | `/api/v1/users`, `/api/v2/users` (glob pattern) |

When multiple rules match, the most specific (longest) path wins.

## API Endpoints

### `GET /auth`

ForwardAuth endpoint. Expects Traefik headers:

| Header | Description |
|--------|-------------|
| `X-Forwarded-Uri` | Original request path |
| `X-Forwarded-Host` | Original host |
| `X-Forwarded-Proto` | Original protocol (http/https) |
| `X-Forwarded-Method` | Original HTTP method |
| `Cookie` | Session cookies |

**Responses:**

| Status | Description |
|--------|-------------|
| `200` | Authorized - includes `X-Auth-User` and `X-Auth-Email` headers |
| `302` | Not authenticated - redirect to OAuth2 login |
| `403` | Authenticated but not authorized |

### `GET /health`

Health check endpoint. Returns `200 OK`.

### `GET /`

Service info endpoint.

## Development

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Run in development mode
AUTHZ_CONFIG_PATH=./authz.yaml \
OAUTH2_PROXY_URL=http://localhost:4180 \
python app.py
```

### Testing Authorization

```bash
# Test with mock headers
curl -v \
  -H "X-Forwarded-Uri: /code/danilo" \
  -H "X-Forwarded-Host: example.com" \
  -H "X-Forwarded-Proto: https" \
  -H "Cookie: _oauth2_proxy=VALID_SESSION" \
  http://localhost:3000/auth
```

### Docker Build

```bash
docker build -t authz-service .
docker run -p 3000:3000 \
  -v ./authz.yaml:/config/authz.yaml:ro \
  -e OAUTH2_PROXY_URL=http://oauth2-proxy:4180 \
  authz-service
```

## Hot Reload

The service automatically reloads `authz.yaml` when the file is modified. No restart required for configuration changes.

## Logging

Logs include:
- Authentication requests with path and host
- User authentication status
- Authorization decisions with reasons

Example log output:
```
INFO - Auth request: GET https://example.com/code/danilo
INFO - User authenticated: danilo (danilo@example.com)
INFO - Access granted: danilo -> /code/danilo (user authorized for /code/danilo)
```

## Security Considerations

1. **Session Validation**: All sessions are validated with OAuth2 Proxy on every request
2. **No Local Storage**: No passwords or tokens stored - relies entirely on OAuth2 Proxy
3. **Config File**: Mount as read-only in production (`:ro`)
4. **Network**: Should only be accessible from Traefik, not directly exposed

## Troubleshooting

### Service can't reach OAuth2 Proxy

```bash
# Check network connectivity
docker compose exec authz-service curl -v http://oauth2-proxy:4180/oauth2/ping
```

### Config not loading

```bash
# Validate YAML syntax
docker compose exec authz-service python -c "import yaml; yaml.safe_load(open('/config/authz.yaml'))"
```

### User not authorized

Check logs for the exact reason:
```bash
docker compose logs authz-service | grep "Access denied"
```

Common causes:
- GitHub username mismatch (case-sensitive)
- Path not in config
- User not in required group

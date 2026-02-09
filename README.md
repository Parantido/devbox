<h1 align="center">
  <br>
  <a href="http://www.techfusion.it"><img src="https://raw.githubusercontent.com/parantido/devbox/master/imgs/devbox.png" alt="DevBox" width="200"></a>
  <br>
  <br>
</h1>

<h4 align="center">An all-in-one deployment for your developers in a single <a href="https://www.docker.com" target="_blank">[docker](https://www.docker.com/)</a> deployment.</h4>

<p align="center">
  <a href="https://badge.fury.io/js/electron-markdownify">
    <img src="https://badge.fury.io/js/electron-markdownify.svg"
         alt="Gitter">
  </a>
  <a href="https://gitter.im/amitmerchant1990/electron-markdownify"><img src="https://badges.gitter.im/amitmerchant1990/electron-markdownify.svg"></a>
  <a href="https://saythanks.io/to/parantido@techfusion.it">
      <img src="https://img.shields.io/badge/SayThanks.io-%E2%98%BC-1EAEDB.svg">
  </a>
  <a href="https://paypal.me/DaniloSantoro">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat">
  </a>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#authentication">Authentication</a> •
  <a href="#troubleshooting">Troubleshooting</a> •
  <a href="#credits">Credits</a> •
  <a href="#license">License</a>
</p>

## Key Features

* Code Everywhere: every dev just need a browser
* Every service deployed in a separate container
* 1 Command Deployment
* **GitHub OAuth Authentication** with fine-grained authorization
  - Per-resource access control
  - User and group-based permissions
  - YAML-based configuration (no database required)
* MySQL Database for Backend Tools
* MySQL Database for Developers already linked in each dev space
* Redis Server for Developers already linked in each dev space
* Per Dev VSCode Area
  - Private Workspace
  - InterDev shared Workspace
  - Extensions Enabled
  - Automatic Port Forwarding Enabled
* Cross platform
  - Windows, macOS and Linux ready.

### TODO
- ✅ Helper Script Provided
- ✅ Traefik Automated Reverse Proxy
- ❌ GitLab deployment
- ✅ ~~Keycloak IAM/SSO~~ Replaced with lightweight OAuth2 Proxy
- ✅ GitHub OAuth Integration
- ✅ YAML-based Authorization Service
- ❌ ~~LDAP Integration~~ I'm not planning to introduce this anymore

## How To Use

To clone and run this application, you'll need [Git](https://git-scm.com), [Docker.io](https://docker.com/) and [Docker Compose V2](https://docs.docker.com/compose/) installed on your computer. From your command line:

```bash
# Clone this repository
$ git clone https://github.com/Parantido/devbox.git

# Go into the repository
$ cd devbox

# Copy the env.sample to .env and edit it to fit your needs
$ cp env.sample .env

# Add/Delete/List DEVs Seats, and update docker-compose.yml
# by rewriting it (Option 4)
$ ./bin/devbox-setup.sh

# Build containers
$ docker compose build

# You can also force build or use a passthrough proxy if your
# infrastructure is blocked by a firewall:
# $ docker compose build --build-arg http_proxy=http://your.proxy.ip:8080 --build-arg https_proxy=http://your.proxy.ip:8080 --no-cache

# Execute/Update containers stack
$ docker compose up -d --remove-orphans

# Or just use the helper script by running it and selecting
# the option 6.
# $ ./bin/devbox-setup.sh
```

> **Note:** Use `docker compose` (with space) instead of `docker-compose` (with hyphen). The old Python-based docker-compose v1.x is incompatible with Docker Engine 25+.

---

## Authentication

DevBox uses a two-layer authentication and authorization system:

1. **OAuth2 Proxy** - Handles GitHub OAuth login and session management
2. **Authorization Service** - Checks user permissions against a YAML configuration

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              User Request                                   │
│                          GET /code/danilo                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               Traefik                                       │
│                         (Reverse Proxy)                                     │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    ForwardAuth Middleware                           │    │
│  │                   → authz-service:3000/auth                         │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Authorization Service                              │
│                                                                             │
│   1. Extract session cookie from request                                    │
│   2. Validate session with OAuth2 Proxy (/oauth2/userinfo)                  │
│   3. If no session → Redirect to GitHub login                               │
│   4. If session valid → Check authorization in authz.yaml                   │
│   5. Return 200 (allowed) or 403 (denied)                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                │                                       │
                │ No Session                            │ Has Session
                ▼                                       ▼
┌───────────────────────────────┐       ┌───────────────────────────────────┐
│       OAuth2 Proxy            │       │         authz.yaml                │
│                               │       │                                   │
│  → Redirect to GitHub         │       │  Check: Is user "danilo.gh"       │
│  → Handle callback            │       │  allowed to access /code/danilo?  │
│  → Set session cookie         │       │                                   │
│  → Redirect back to resource  │       │  ✓ Yes → 200 (proceed)            │
└───────────────────────────────┘       │  ✗ No  → 403 (forbidden)          │
                                        └───────────────────────────────────┘
```

### Setup GitHub OAuth

#### Step 1: Create a GitHub OAuth App

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click **"New OAuth App"**
3. Fill in the details:

| Field | Value |
|-------|-------|
| Application name | `DevBox Auth` (or your preferred name) |
| Homepage URL | `https://your-hostname.your-domain.com` |
| Authorization callback URL | `https://your-hostname.your-domain.com/oauth2/callback` |

4. Click **"Register application"**
5. Copy the **Client ID**
6. Generate and copy a **Client Secret**

#### Step 2: Configure Environment Variables

Edit the `.env` file in the project root:

```bash
# Generate a secure cookie secret (32 bytes, base64 encoded)
openssl rand -base64 32 | tr -- '+/' '-_'
```

Update these variables in `.env`:

```env
# GitHub OAuth Configuration
GITHUB_CLIENT_ID=your_github_client_id_here
GITHUB_CLIENT_SECRET=your_github_client_secret_here
OAUTH2_COOKIE_SECRET=your_generated_cookie_secret_here
```

#### Step 3: Configure Authorization Rules

Edit `config/authz/authz.yaml` to define who can access what:

```yaml
# Default policy for paths not matching any resource
default_policy: deny

# User groups for easier management
groups:
  admins:
    - admin-github-username
  developers:
    - dev1-github-username
    - dev2-github-username

# Protected resources and their access rules
resources:
  # User-specific code-server instances
  /code/danilo:
    users:
      - danilo-github-username

  /code/filippo:
    users:
      - filippo-github-username

  # Shared resources
  /code/tracker:
    groups:
      - developers

  # Resource accessible by all authenticated users
  /public-dashboard:
    authenticated: true

  # Admin-only resource
  /admin:
    groups:
      - admins
```

**Important:** Use the exact GitHub username (case-sensitive) as it appears on GitHub.

#### Step 4: Build and Deploy

```bash
cd /path/to/devbox/composers.d

# Build the services
docker compose build authz-service oauth2-proxy

# Start the stack
docker compose up -d

# Check logs
docker compose logs -f authz-service oauth2-proxy
```

### Authorization Configuration Reference

The authorization config file (`config/authz/authz.yaml`) supports:

#### Path Matching

| Pattern | Description | Example Match |
|---------|-------------|---------------|
| `/code/danilo` | Exact prefix match | `/code/danilo`, `/code/danilo/file.txt` |
| `/code/danilo/*` | Explicit wildcard | Same as above |
| `/api/*/users` | Glob pattern | `/api/v1/users`, `/api/v2/users` |

#### Access Rules

```yaml
resources:
  /some/path:
    # Allow specific users
    users:
      - github-username-1
      - github-username-2

    # Allow groups (expanded from groups section)
    groups:
      - developers
      - admins

    # Allow any authenticated user (overrides users/groups)
    authenticated: true
```

#### Groups

```yaml
groups:
  # Simple list
  developers:
    - user1
    - user2

  # Nested definition (also supported)
  admins:
    users:
      - admin1
      - admin2
```

### Adding a New User

1. Get their GitHub username
2. Edit `config/authz/authz.yaml`:
   ```yaml
   resources:
     /code/newuser:
       users:
         - their-github-username
   ```
3. Changes are picked up automatically (no restart needed)

### Adding a New Code-Server Instance

1. Add the user to `authz.yaml` as shown above
2. Use the helper script or manually add to `docker-compose.yml`:
   ```yaml
   code-newuser:
     # ... (use the template from templates/docker-compose_delta-template.yml)
     labels:
       - "traefik.http.routers.code-newuser.middlewares=authz@docker,code-newuser-slash,code-newuser-strip"
       # ... other labels
   ```
3. Run `docker compose up -d`

### Portal and Logout

The DevBox Portal is a Next.js application that provides:
- **Landing page** at `/` with workspace links
- **User dashboard** showing available workspaces
- **Logout functionality** via the "Sign Out" button

#### Logout URL

Users can log out by visiting:
```
https://your-hostname.your-domain/oauth2/sign_out?rd=https://your-hostname.your-domain/
```

Or by clicking the "Sign Out" button in the portal header.

#### Customizing Workspaces

Edit the `WORKSPACES` array in `containers_build/portal/app/page.tsx` to add or remove workspaces from the portal:

```typescript
const WORKSPACES: Workspace[] = [
  {
    name: 'User Name',
    path: '/code/username/',
    description: 'Workspace description',
  },
  // Add more workspaces...
]
```

After changes, rebuild the portal:
```bash
docker compose build portal
docker compose up -d portal
```

---

## Troubleshooting

### Authentication Issues

#### "404 Not Found" on /oauth2/callback

**Cause:** OAuth2 Proxy service is not running or not routed correctly.

**Solution:**
```bash
# Check if oauth2-proxy is running
docker compose ps oauth2-proxy

# Check logs
docker compose logs oauth2-proxy

# Verify Traefik routing
curl -I https://your-host.domain/oauth2/ping
```

#### "403 Forbidden" after logging in

**Cause:** User is authenticated but not authorized for the resource.

**Solution:**
1. Check the authz-service logs to see the exact reason:
   ```bash
   docker compose logs authz-service | grep -i "access denied"
   ```
2. Verify the GitHub username in `authz.yaml` matches exactly (case-sensitive)
3. Ensure the resource path in `authz.yaml` matches the URL you're accessing

#### Redirect loop or "Too many redirects"

**Cause:** Cookie domain mismatch or OAuth2 Proxy misconfiguration.

**Solution:**
1. Check the `OAUTH2_PROXY_COOKIE_DOMAINS` in docker-compose.yml matches your domain
2. Clear browser cookies for the domain
3. Check OAuth2 Proxy logs:
   ```bash
   docker compose logs oauth2-proxy | grep -i error
   ```

#### "Invalid redirect URL" from GitHub

**Cause:** The callback URL doesn't match what's configured in GitHub OAuth App.

**Solution:**
1. Go to GitHub → Settings → Developer settings → OAuth Apps
2. Verify the callback URL is exactly: `https://your-hostname.your-domain/oauth2/callback`
3. Check there are no trailing slashes or typos

### Service Connectivity Issues

#### authz-service can't reach oauth2-proxy

**Cause:** Network configuration issue or oauth2-proxy not running.

**Solution:**
```bash
# Check both services are on the same network
docker network inspect devbox_code-space

# Test connectivity from authz-service
docker compose exec authz-service curl -v http://oauth2-proxy:4180/oauth2/ping
```

#### Code-server loads but shows "Bad Gateway"

**Cause:** Code-server container not running or wrong port.

**Solution:**
```bash
# Check code-server is running
docker compose ps code-danilo

# Check code-server logs
docker compose logs code-danilo

# Verify the health check
docker compose exec code-danilo curl -I http://localhost:8443
```

### Debugging Commands

#### View all authentication requests

```bash
# Watch authz-service logs in real-time
docker compose logs -f authz-service

# Filter for specific user
docker compose logs authz-service | grep "danilo"
```

#### Test authorization without browser

```bash
# Get a valid session cookie first (from browser dev tools)
# Then test the auth endpoint directly:

curl -v \
  -H "X-Forwarded-Uri: /code/danilo" \
  -H "X-Forwarded-Host: your-host.domain" \
  -H "X-Forwarded-Proto: https" \
  -H "Cookie: _oauth2_proxy=YOUR_SESSION_COOKIE" \
  http://localhost:3000/auth
```

#### Check Traefik routing

```bash
# Access Traefik dashboard (if enabled)
# Default: http://localhost:8080/dashboard/

# Or check routers via API
curl http://localhost:8080/api/http/routers | jq
```

#### Verify OAuth2 Proxy session

```bash
# Check if session is valid
curl -v \
  -H "Cookie: _oauth2_proxy=YOUR_SESSION_COOKIE" \
  http://localhost:4180/oauth2/userinfo
```

### Configuration Validation

#### Validate authz.yaml syntax

```bash
# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('config/authz/authz.yaml'))"

# Or with Docker
docker compose exec authz-service python -c "import yaml; print(yaml.safe_load(open('/config/authz.yaml')))"
```

#### Test configuration changes

The authz-service automatically reloads `authz.yaml` when modified. To verify:

```bash
# Watch logs while editing the config
docker compose logs -f authz-service &

# Edit the config
vim config/authz/authz.yaml

# You should see: "Loaded authorization config from /config/authz.yaml"
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `KeyError: 'ContainerConfig'` | Old docker-compose with new Docker | Install Docker Compose V2 |
| `Unknown option --proxy-path-passthrough` | Invalid code-server flag | Remove the flag (not supported) |
| `OAuth2 Proxy returned 401` | Invalid/expired session | Clear cookies, re-login |
| `no matching resource, default policy: deny` | Path not in authz.yaml | Add the path to authz.yaml |
| `Connection refused` to oauth2-proxy | Service not running | `docker compose up -d oauth2-proxy` |

### Logs Location

| Service | View Logs |
|---------|-----------|
| Traefik | `docker compose logs code-proxy` |
| OAuth2 Proxy | `docker compose logs oauth2-proxy` |
| Authz Service | `docker compose logs authz-service` |
| Code Server | `docker compose logs code-<username>` |

---

## Emailware

DevBox is an [emailware](https://en.wiktionary.org/wiki/emailware). Meaning, if you liked using this integration or it has helped you in any way, I'd like you send me an email at <parantido@techfusion.it> about anything you'd want to say about this software. I'd really appreciate it!

## Credits

This software uses the following open source packages:

- [Docker.io](https://www.docker.com/)
- [Node.js](https://nodejs.org/)
- [Traefik](https://traefik.io/traefik/)
- [Code Server](https://github.com/coder/code-server)
- [OAuth2 Proxy](https://oauth2-proxy.github.io/oauth2-proxy/)
- [Python](https://www.python.org/)
- [Flask](https://flask.palletsprojects.com/)

## Support

<a href="https://www.buymeacoffee.com/parantido" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

## You may also like...

- [Tech Fusion ITc](https://www.techfusion.it) - Tech Fusion ITc Consultant

## License

MIT

---

> [techfusion.it](https://www.techfusion.it) &nbsp;&middot;&nbsp;
> GitHub [@Parantido](https://github.com/Parantido) &nbsp;&middot;&nbsp;

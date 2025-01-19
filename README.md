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
  <a href="#emailware">Emailware</a> •
  <a href="#credits">Credits</a> •
  <a href="#license">License</a>
</p>

## Key Features

* Code Everywhere: every dev just need a browser
* Every service deployed in a separate container
* 1 Command Deployment
* Live Tracker (Powered with [LeanTime.io](https://leantime.io)) for:
  - Projects Management
  - Milestone Arrangement
  - ToDo Kanban / Table / List
  - Goals set
  - Ideas share
  - Knowledge base management (Wiki/MarkDown)
  - Blueprints & Templates
  - Timesheet and Hours Accounting
  - Reports
  - Retrospective management
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
- ✅ Keycloak IAM/SSO
- ✅ --> Traefik Proxy Integration
- ✅ --> [Authentication Middleware](containers_build/auth-service/README.md)
- ❌ --> LDAP integration

## How To Use

To clone and run this application, you'll need [Git](https://git-scm.com), [Docker.io](https://docker.com/) and [Docker-Compose](https://docs.docker.com/compose/) installed on your computer. From your command line:

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
$ docker-compose build

# You can also force build or use a passthrough proxy if your
# infrastructure is blocked by a firewall:
# $ docker-compose build --build-arg http_proxy=http://your.proxy.ip:8080 --build-arg https_proxy=http://your.proxy.ip:8080 --no-cache

# Execute/Update containers stack
$ docker-compose up -d --remove-orphans

# Or just use the helper script by running it and selecting
# the option 6.
# $ ./bin/devbox-setup.sh
```

## Emailware

DevBox is an [emailware](https://en.wiktionary.org/wiki/emailware). Meaning, if you liked using this integration or it has helped you in any way, I'd like you send me an email at <parantido@techfusion.it> about anything you'd want to say about this software. I'd really appreciate it!

## Credits

This software uses the following open source packages:

- [Docker.io](https://www.docker.com/)
- [Node.js](https://nodejs.org/)
- [Traefik](https://traefik.io/traefik/)
- [Code Server](https://github.com/coder/code-server)
- [Keycloak](https://www.keycloak.org/)
- [Python](https://www.python.org/)

## Support

<a href="https://www.buymeacoffee.com/parantido" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

## You may also like...

- [Tech Fusion ITc](https://www.techfusion.it) - Tech Fusion ITc Consultant

## License

MIT

---

> [techfusion.it](https://www.techfusion.it) &nbsp;&middot;&nbsp;
> GitHub [@Parantido](https://github.com/Parantido) &nbsp;&middot;&nbsp;


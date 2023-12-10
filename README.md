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
- ✅ This is only a placeholder :)
- ❌ GitLab deployment
- ❌ Unified authentication (KeyLocker?)
- ❌ --> oAuth2 Proxy
- ❌ --> Nginx Reverse Proxy

## How To Use

To clone and run this application, you'll need [Git](https://git-scm.com), [Docker.io](https://docker.com/) and [Docker-Compose](https://docs.docker.com/compose/) installed on your computer. From your command line:

```bash
# Clone this repository
$ git clone https://github.com/Parantido/devbox.git

# Go into the repository
$ cd devbox

# Edit env.sample and docker-compose.sample.yml file
$ cp env.sample .env
$ cp docker-compose.sample.yml docker-compose.yml

# Add or remove devs by using interactive helper
$ ./users_handler.sh

# Install dependencies
$ docker-compose build

# Run the app
$ docker-compose up -d 
```

## Emailware

DevBox is an [emailware](https://en.wiktionary.org/wiki/emailware). Meaning, if you liked using this integration or it has helped you in any way, I'd like you send me an email at <parantido@techfusion.it> about anything you'd want to say about this software. I'd really appreciate it!

## Credits

This software uses the following open source packages:

- [Docker.io](https://www.docker.com/)
- [Node.js](https://nodejs.org/)

## Support

<a href="https://www.buymeacoffee.com/parantido" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

<p>Or</p> 

<a href="https://www.patreon.com/parantido">
	<img src="https://c5.patreon.com/external/logo/become_a_patron_button@2x.png" width="160">
</a>

## You may also like...

- [Tech Fusion ITc](https://www.techfusion.it) - Tech Fusion ITc Consultant

## License

MIT

---

> [techfusion.it](https://www.techfusion.it) &nbsp;&middot;&nbsp;
> GitHub [@Parantido](https://github.com/Parantido) &nbsp;&middot;&nbsp;


FROM ubuntu:22.04

ARG SUDO
ENV SUDO=$SUDO
ENV TZ=Etc/UTC

# To avoid internet overload every build
ARG APT_PROXY
ENV APT_PROXY $APT_PROXY
ENV HTTP_PROXY $HTTP_PROXY
ENV HTTPS_PROXY $HTTPS_PROXY
RUN if [ ! -z "$APT_PROXY" ]; then echo "Acquire::http::Proxy \"${APT_PROXY}\";" > /etc/apt/apt.conf.d/02proxy ; fi

# Update and install some basic packages to register a PPA.
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update
RUN apt-get -y install sudo apt-utils aptitude curl wget ca-certificates curl gnupg git

# Install additional packages if SUDO
RUN echo "SUDO? $SUDO" ; if [ -z "$SUDO" ] ; then echo "Not a sudoer ... do nothing" ; else apt-get -y install netcat net-tools iputils-ping iputils-tracepath iproute2 ; fi

# Use a PPA to ensure a specific version of Node (the default Node on
# Ubuntu 20.04 is v10, which is too old):
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# Now we can install the bulk of the packages:
RUN apt-get -y update
RUN apt-get -y install nodejs 

# Install Code Server
RUN curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep "browser_download_url.*amd64.deb" | cut -d : -f 2,3 | tr -d \" | wget --quiet -i - \
    && dpkg -i *.deb && rm -rf /var/lib/apt/lists/*

# Copy needed binary files
COPY ./bin/looper.sh /usr/local/bin/looper.sh
COPY ./bin/boot_run.sh /usr/local/bin/boot_run.sh

# Create unprivileged user
RUN adduser --gecos '' --disabled-password coder 
	# && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# Switch to unprivileged user
USER 1000
ENV USER=coder
WORKDIR /config
ENV HOME /config

ENTRYPOINT ["/usr/local/bin/boot_run.sh"]

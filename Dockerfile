FROM ubuntu:24.04

# local image user ID and group ID to not run as root
ENV USER_UID=6969
ENV USER_GID=6969

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

RUN \
  # update system packages ...
  apt-get update \
  && apt-get install -y --no-install-recommends \
    binutils \
    coreutils \
    adduser \
    jsvc \
    curl \
    gnupg \
    libcap2 \
    logrotate \
    openjdk-17-jre-headless \
  # install MongoDB
  && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor \
  && echo "deb [ arch=amd64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    mongodb-org \
  # get current unifi version
  && __V=$(curl -ksX GET https://dl-origin.ubnt.com/unifi/debian/dists/stable/ubiquiti/binary-amd64/Packages | grep 'Version:' | cut -d' ' -f2 | cut -d'-' -f1) \
  # install unifi
  && curl -ko /tmp/unifi.deb -L "https://dl.ui.com/unifi/${__V}/unifi_sysvinit_all.deb" \
  && dpkg -i /tmp/unifi.deb \
  # make entry executable
  && chmod +x /docker-entrypoint.sh \
  # make expected static file volume mounts
  && mkdir -p \
    /usr/lib/unifi/data \
    /usr/lib/unifi/logs \
    /usr/lib/unifi/run  \
    /var/run/unifi/     \
    /var/log/unifi/     \
  # create image user
  && groupadd -g $USER_GID app_user \
  && useradd --no-log-init -r -u $USER_UID -g $USER_GID app_user \
  # change app ownership to image user
  && chown -R ${USER_UID}:${USER_GID} \
    /usr/lib/unifi/ \
    /var/run/unifi/ \
    /var/log/unifi/ \
  # make the unifi user the same as the app user
  && usermod -o -u ${USER_UID} unifi \
  && groupmod -o -g ${USER_GID} unifi \
  # layer cleanup ...
  && apt-get autoremove -y \
  && apt-get clean \
  && rm -rf \
    /tmp/* \
    /var/tmp/* \
    /var/lib/apt/lists/*

# define application volumes
VOLUME ["/usr/lib/unifi/data","/usr/lib/unifi/logs","/usr/lib/unifi/run"]

WORKDIR /usr/lib/unifi/

USER app_user

ENTRYPOINT ["/docker-entrypoint.sh"]


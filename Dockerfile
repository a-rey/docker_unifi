FROM ubuntu:22.04

# local image user ID and group ID to not run as root
ENV USER_UID 6969
ENV USER_GID 6969

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
      gpg \
      libcap2 \
      logrotate \
      openjdk-17-jre-headless \
    # allow for libssl1.1 to be installed for MongoDB 3.6
    && echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list \
    # install MongoDB 
    && curl -fsSL https://www.mongodb.org/static/pgp/server-3.6.asc | gpg -o /etc/apt/trusted.gpg.d/mongodb-server-3.6.gpg --dearmor \
    && echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list \
    && apt-key list | grep "expired: " | sed -ne 's|pub .*/\([^ ]*\) .*|\1|gp' | xargs -n1 apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys \
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
    # make expected static file volume mounts and nginx files
    && mkdir -p /usr/lib/unifi/data \
    && mkdir -p /usr/lib/unifi/logs \
    && mkdir -p /usr/lib/unifi/run \
    # create image user
    && groupadd -g $USER_GID app_user \
    && useradd --no-log-init -r -u $USER_UID -g $USER_GID app_user \
    # change app ownership to image user
    && chown -R ${USER_UID}:${USER_GID} /usr/lib/unifi/ \
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


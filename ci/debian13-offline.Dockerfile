FROM debian:trixie-slim

ARG DEB_FILE

COPY ${DEB_FILE} /tmp/deepseek-harness.deb
COPY desktop-session.sh /usr/local/bin/desktop-session.sh
COPY debian13-package-check.sh /usr/local/bin/debian13-package-check.sh

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    /tmp/deepseek-harness.deb \
    dbus-x11 \
    imagemagick \
    libglib2.0-bin \
    openbox \
    procps \
    xauth \
    xdotool \
    xvfb \
  && rm -f /tmp/deepseek-harness.deb \
  && rm -rf /var/lib/apt/lists/* \
  && chmod 0755 /usr/local/bin/desktop-session.sh /usr/local/bin/debian13-package-check.sh

ENTRYPOINT ["/usr/local/bin/debian13-package-check.sh"]

FROM alpine:3.8

LABEL Automated testing environment to run uetomae-development-process

ENV AUTOTEST_HOME /var/autotest
ENV AUTOTEST_BIN $AUTOTEST_HOME/bin
ENV AUTOMATA_HOME $AUTOTEST_HOME/automata
ENV AUTOMATA_BIN $AUTOMATA_HOME/bin
ENV AUTOMATA_TEST $AUTOTEST_HOME/test
ENV PATH $PATH:$AUTOTEST_BIN:$AUTOMATA_BIN

# Information about test runner
ENV AUTOMATA_GIT_REPO https://github.com/uetomae/automata
ENV AUTOMATA_GIT_BRANCH master

# Variables for headless browser
ENV SCREEN_COLOR_DEPTH 24
ENV SCREEN_HEIGHT 1080
ENV SCREEN_WIDTH 1920

VOLUME $AUTOMATA_TEST

# Install base system and dependencies
RUN apk add --no-cache \
    python \
    build-base \
    openssl \
    openssl-dev \
    bash \
    git \
    curl \
    jq \
    bats

# Install robotframework and libraries
RUN apk add --no-cache --virtual=.build-deps \
    py-pip \
    py-boto \
    libffi-dev \
    && pip install --upgrade pip \
    && pip install \
    robotframework-selenium2library \
    robotframework-appiumlibrary \
    robotframework-excellentlibrary \
    && apk del .build-deps

# Install chromium browser and disabling sandbox and gpu options as default of it
RUN apk add --no-cache \
    udev \
    ttf-freefont \
    chromium \
    chromium-chromedriver \
    xvfb \
    && sed -i "s/self._arguments\ =\ \[\]/self._arguments\ =\ \['--no-sandbox',\ '--disable-gpu'\]/" /usr/lib/python2.7/site-packages/selenium/webdriver/chrome/options.py

# Install Japanese font
RUN mkdir /noto
ADD https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip /noto
WORKDIR /noto
RUN unzip NotoSansCJKjp-hinted.zip && \
    mkdir -p /usr/share/fonts/noto && \
    cp *.otf /usr/share/fonts/noto && \
    chmod 644 -R /usr/share/fonts/noto/ && \
    fc-cache -fv
WORKDIR /
RUN rm -rf /noto

# Install alpine-pkg-glib to fix compatibility problem with Java 8
# See: https://github.com/gliderlabs/docker-alpine/issues/11
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.28-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

# Install BrowserStackLocal
RUN cd \
&&  wget -q https://www.browserstack.com/browserstack-local/BrowserStackLocal-linux-x64.zip \
&&  unzip BrowserStackLocal-linux-x64.zip \
&&  rm BrowserStackLocal-linux-x64.zip \
&&  mv BrowserStackLocal /usr/local/bin/

# Clone automata
RUN git clone -b $AUTOMATA_GIT_BRANCH $AUTOMATA_GIT_REPO $AUTOMATA_HOME

COPY bin/uetomae-automata-update $AUTOTEST_BIN/

WORKDIR $AUTOMATA_TEST
CMD ${AUTOMATA_BIN}/run_test

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
RUN apk add --update \
    py-pip \
    build-base \
    py-boto \
    libffi-dev \
    openssl \
    openssl-dev \
    bash \
    git \
    curl \
    jq \
    udev \
    chromium \
    chromium-chromedriver \
    firefox-esr \
    xvfb \
    ttf-freefont \
    && pip install --upgrade pip \
    && rm -rf /var/cache/apk/**/

# Install robotframework and libraries
RUN pip install \
    robotframework-extendedselenium2library \
    robotframework-appiumlibrary \
    robotframework-excellentlibrary

# Disabling sandbox and gpu options as default of chrome browser
RUN sed -i "s/self._arguments\ =\ \[\]/self._arguments\ =\ \['--no-sandbox',\ '--disable-gpu'\]/" /usr/lib/python2.7/site-packages/selenium/webdriver/chrome/options.py

# Clone automata
RUN git clone -b $AUTOMATA_GIT_BRANCH $AUTOMATA_GIT_REPO $AUTOMATA_HOME

COPY bin/uetomae-automata-update $AUTOTEST_BIN/

WORKDIR $AUTOMATA_TEST
CMD ${AUTOMATA_BIN}/run_test

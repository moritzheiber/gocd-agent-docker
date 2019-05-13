FROM moritzheiber/alpine-base
LABEL maintainer="Moritz Heiber <hello@heiber.im>"

ARG MAJOR_VERSION="19.3.0"
ARG BATCH_VERSION="8959"
ARG GOCD_RELEASE="${MAJOR_VERSION}-${BATCH_VERSION}"
ARG GOCD_CHECKSUM="375f961bd0279fdb0d5dab8e47dabd6a2b041bed3583e55bd0a4a328d06e39da"
ARG COMPOSE_VERSION="1.22.0"
ARG COMPOSE_CHECKSUM="f679a24b93f291c3bffaff340467494f388c0c251649d640e661d509db9d57e9"

ENV GO_DIR="/gocd"
ENV GO_CONFIG_DIR="${GO_DIR}/config" \
  LANG="en_US.UTF8" \
  AGENT_AUTO_REGISTER_RESOURCES="main"

# Installing etc gem because of https://github.com/bundler/bundler/issues/6640
RUN apk --no-cache add curl unzip bash openjdk8-jre git docker ruby-dev ruby ruby-etc \
    ruby-io-console jq tar build-base zlib-dev libffi-dev ca-certificates terraform && \
  echo "gem: --no-rdoc --no-ri" > /etc/gemrc && \
  gem install etc bundler && \
  curl -Lo /usr/bin/docker-compose https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-Linux-x86_64 && \
  echo "${COMPOSE_CHECKSUM}  /usr/bin/docker-compose" | sha256sum -c - && \
  chmod +x /usr/bin/docker-compose && \
  curl -Lo /tmp/gocd.zip \
    https://download.gocd.org/binaries/${GOCD_RELEASE}/generic/go-agent-${GOCD_RELEASE}.zip && \
  echo "${GOCD_CHECKSUM}  /tmp/gocd.zip" | sha256sum -c - && \
  mkdir -p /tmp/extraced && \
  unzip /tmp/gocd.zip -d /tmp/extracted && \
  mv /tmp/extracted/go-agent-${MAJOR_VERSION} ${GO_DIR} && \
  addgroup -S gocd && \
  adduser -h /home/gocd -s /bin/sh -G gocd -SD gocd && \
  install -d -o gocd -g gocd ${GO_CONFIG_DIR} ${GO_DIR}/runtime ${GO_DIR}/runtime/config && \
  apk --no-cache del --purge curl unzip && \
  rm -r /tmp/gocd.zip /tmp/extracted

ADD config/logback.xml ${GO_CONFIG_DIR}/agent-launcher-logback.xml
ADD config/logback.xml ${GO_CONFIG_DIR}/agent-bootstrapper-logback.xml
ADD templates/autoregister.properties ${GO_DIR}/templates/autoregister.properties

EXPOSE 8152/tcp
WORKDIR ${GO_DIR}/runtime
USER gocd

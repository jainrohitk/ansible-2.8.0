FROM alpine:3.7

ENV ANSIBLE_VERSION 2.8.0

ENV BUILD_PACKAGES \
  bash \
  curl \
  tar \
  openssh-client \
  sshpass \
  git \
  python \
  python3 \
  py-boto \
  py-dateutil \
  py-httplib2 \
  py-jinja2 \
  py-paramiko \
  py-pip \
  py-yaml \
  ca-certificates

# If installing ansible@testing
#RUN \
#	echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> #/etc/apk/repositories

RUN set -x && \
    \
    echo "==> Adding build-dependencies..."  && \
    apk --update add --virtual build-dependencies \
      gcc \
      musl-dev \
      libffi-dev \
      openssl-dev \
      python-dev && \
    \
    echo "==> Upgrading apk and system..."  && \
    apk update && apk upgrade && \
    \
    echo "==> Adding Python runtime..."  && \
    apk add --no-cache ${BUILD_PACKAGES} && \
    pip install --upgrade pip && \
    pip install python-keyczar docker-py && \
    \
    echo "==> Installing Ansible..."  && \
    pip install ansible==${ANSIBLE_VERSION} && \
    pip install pylint && \
    apk add python3-dev gcc musl-dev && \
    pip3 install pylint && \
    \
    echo "==> Adding hosts for convenience..."  && \
    mkdir -p /etc/ansible /ansible && \
    echo "[local]" >> /etc/ansible/hosts && \
    echo "localhost" >> /etc/ansible/hosts && \
    mkdir /ansible/playbooks

ENV ANSIBLE_GATHERING smart
ENV ANSIBLE_HOST_KEY_CHECKING false
ENV ANSIBLE_RETRY_FILES_ENABLED false
ENV ANSIBLE_ROLES_PATH /ansible/playbooks/roles
ENV ANSIBLE_SSH_PIPELINING True
ENV PYTHONPATH /ansible/lib
ENV PATH /ansible/bin:$PATH
ENV ANSIBLE_LIBRARY /ansible/library

RUN set -x && \
    apk --update add shadow && \
    groupadd --gid 2010 pcms-builder && \
    useradd --gid 2010 --uid 2010 --create-home pcms-builder && \
    pip3 install requests && \
    pip install ansible-lint && \
    \
    echo "==> Cleaning up..."  && \
    apk del build-dependencies && \
    apk del musl-dev gcc && \
    apk del python-dev && \
    apk del python3-dev && \
    rm -rf /var/cache/apk/*

RUN chmod ugo+rw /ansible/playbooks
ENV HOME /ansible/playbooks
WORKDIR /ansible/playbooks
MAINTAINER jain.rohitk@gmail.com

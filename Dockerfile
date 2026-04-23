FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git openssh-client jq \
    python3 python3-pip \
    ripgrep fd-find tree \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g \
         bash-language-server \
         markdown-language-server \
         typescript typescript-language-server \
         vscode-langservers-extracted \
         yaml-language-server \
         dockerfile-language-server-nodejs \
         pyright \
    && npm cache clean --force

ARG UID=1000
RUN userdel -r ubuntu 2>/dev/null; useradd -m -s /bin/bash -u ${UID} coder

USER coder
WORKDIR /home/coder
ENV HOME=/home/coder

RUN mkdir -p /home/coder/.local/share/opencode /home/coder/.local/state/opencode

RUN pip3 install --user nb-cli

# Install OpenCode (always latest)
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH=/home/coder/.opencode/bin:/home/coder/.local/bin:$PATH

ENTRYPOINT ["opencode"]

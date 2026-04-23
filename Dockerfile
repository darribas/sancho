FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git openssh-client jq \
    python3 \
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

RUN curl -fsSL https://raw.githubusercontent.com/jupyter-ai-contrib/nb-cli/main/install.sh | bash

# Install OpenCode (always latest)
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH=/home/coder/.opencode/bin:/home/coder/.nb-cli/bin:$PATH

ENTRYPOINT ["opencode"]

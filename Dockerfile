FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git openssh-client jq nodejs npm python3-pip \
     && rm -rf /var/lib/apt/lists/*

ARG UID=1000
RUN userdel -r ubuntu 2>/dev/null; useradd -m -s /bin/bash -u ${UID} coder

USER coder
WORKDIR /home/coder
ENV HOME=/home/coder

RUN mkdir -p /home/coder/.local/share/opencode /home/coder/.local/state/opencode

# Install LSP servers via npm
RUN npm install -g \
    python-lsp-server \
    pyright \
    bash-language-server \
    markdown-language-server && \
    npm cache clean --force

# Install Python LSP dependencies via pip
RUN pip3 install --break-system-packages \
    pylsp-mypy \
    pylsp-flake8 \
    pycodestyle \
    pylint || true

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash

ENV PATH=/home/coder/.opencode/bin:$PATH

ENTRYPOINT ["opencode"]

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates git openssh-client jq \
    && rm -rf /var/lib/apt/lists/*

ARG UID=1000
RUN userdel -r ubuntu 2>/dev/null; useradd -m -s /bin/bash -u ${UID} coder

USER coder
WORKDIR /home/coder
ENV HOME=/home/coder

RUN mkdir -p /home/coder/.local/share/opencode /home/coder/.local/state/opencode

# Install OpenCode
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH=/home/coder/.opencode/bin:$PATH

ENTRYPOINT ["opencode"]

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    checkinstall \
    g++ \
    ccache \
    make \
    lcov \
    libpcre3-dev \
    zlib1g-dev \
    libssl-dev \
    sudo \
    bc \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /

COPY scripts/build_env.sh /usr/local/bin/build_env.sh
COPY src/ /src
RUN chmod +x /usr/local/bin/build_env.sh


USER builder

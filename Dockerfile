FROM ubuntu:22.04


RUN apt update && apt install -y \
    build-essential \
    checkinstall \
    g++ \
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

COPY build_env.sh /usr/local/bin/build_env.sh
RUN chmod +x /usr/local/bin/build_env.sh

WORKDIR /src
USER builder

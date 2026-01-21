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
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /work /artifacts /reports

RUN useradd -ms /bin/bash builder && \
    chown -R builder:builder /work /artifacts /reports

COPY build_env.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build_env.sh

RUN useradd -ms /bin/bash builder && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /work

USER builder


FROM ubuntu:22.04

ENV NGINX_VERSION=1.24.0 

RUN apt-get update && apt-get install -y \
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
    tar \
    wget \
    curl \
    ca-certificates \
    gnupg2 \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /src
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz --strip-components=1 && \
    rm -f nginx-${NGINX_VERSION}.tar.gz && \
    echo "✓ NGINX ${NGINX_VERSION} sources downloaded"

RUN ls -la configure && echo "✓ Configure script ready"

COPY build_env.sh /usr/local/bin/build_env.sh
RUN chmod +x /usr/local/bin/build_env.sh




RUN chown -R builder:builder /src
USER builder

CMD ["/bin/bash", "-c", "echo 'Build environment ready. Nginx: ${NGINX_VERSION}' && pwd && ls -la"]

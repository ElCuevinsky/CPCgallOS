FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        coreutils \
        curl \
        dosfstools \
        file \
        findutils \
        gawk \
        gnupg \
        grub-common \
        jq \
        mtools \
        openssl \
        python3 \
        ripgrep \
        rsync \
        shellcheck \
        snapd \
        squashfs-tools \
        xorriso \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ENTRYPOINT []

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash steam

USER steam
WORKDIR /home/steam

RUN mkdir -p /home/steam/steamcmd \
    && curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xz -C /home/steam/steamcmd

COPY --chown=steam:steam install-server.sh /home/steam/install-server.sh
RUN chmod +x /home/steam/install-server.sh \
    && /home/steam/install-server.sh \
    && rm /home/steam/install-server.sh

ARG METAMOD_VERSION=1.12.0
ARG METAMOD_BUILD=1227
ARG SOURCEMOD_VERSION=1.12.0
ARG SOURCEMOD_BUILD=7253

RUN curl -fsSL --retry 3 \
        "https://github.com/alliedmodders/metamod-source/releases/download/${METAMOD_VERSION}.${METAMOD_BUILD}/mmsource-${METAMOD_VERSION}-git${METAMOD_BUILD}-linux.tar.gz" \
        -o /tmp/metamod.tar.gz \
    && tar -xzf /tmp/metamod.tar.gz -C /home/steam/css-serverfiles/cstrike \
    && rm /home/steam/css-serverfiles/cstrike/addons/metamod.vdf \
    && curl -fsSL --retry 3 \
        "https://github.com/alliedmodders/sourcemod/releases/download/${SOURCEMOD_VERSION}.${SOURCEMOD_BUILD}/sourcemod-${SOURCEMOD_VERSION}-git${SOURCEMOD_BUILD}-linux.tar.gz" \
        -o /tmp/sourcemod.tar.gz \
    && tar -xzf /tmp/sourcemod.tar.gz -C /home/steam/css-serverfiles/cstrike \
    && test -f /home/steam/css-serverfiles/cstrike/addons/metamod/bin/linux64/metamod.2.css.so \
    && test -f /home/steam/css-serverfiles/cstrike/addons/sourcemod/bin/x64/sourcemod.2.css.so \
    && rm /tmp/metamod.tar.gz /tmp/sourcemod.tar.gz

COPY --chown=steam:steam docker-entrypoint.sh /home/steam/docker-entrypoint.sh
RUN chmod +x /home/steam/docker-entrypoint.sh

ENV CSS_MAP=de_dust2 \
    CSS_MAXPLAYERS=16 \
    CSS_PORT=27015 \
    CSS_TICKRATE=66

EXPOSE 27015/tcp 27015/udp 27020/udp

WORKDIR /home/steam/css-serverfiles
COPY --chown=steam:steam config/ cstrike/

ENTRYPOINT ["/usr/bin/tini", "--", "/home/steam/docker-entrypoint.sh"]

FROM debian:bookworm-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        bzip2 \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386 \
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
ARG EXTENDED_MAPCONFIG_COMMIT=2b0dbf9b2702a5a3e5e918bc75b1502238b74f2c

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

WORKDIR /home/steam/css-serverfiles
COPY --chown=steam:steam config/ cstrike/

RUN curl -fsSL --retry 3 \
        "https://raw.githubusercontent.com/Nekromio/extendedmapconfig/${EXTENDED_MAPCONFIG_COMMIT}/addons/sourcemod/scripting/extendedmapconfig.sp" \
        -o cstrike/addons/sourcemod/scripting/extendedmapconfig.sp \
    && cstrike/addons/sourcemod/scripting/spcomp \
        cstrike/addons/sourcemod/scripting/extendedmapconfig.sp \
        -o cstrike/addons/sourcemod/plugins/extendedmapconfig.smx \
    && rm cstrike/addons/sourcemod/scripting/extendedmapconfig.sp

RUN for map in \
        ba_jail_electric_razor_v6 \
        ba_jail_blackops \
        ba_jail_canyondam_v6_fix \
        surf_ski_2 \
        surf_utopia_v3 \
        surf_beginner \
        bhop_badges \
        bhop_arcane_v1 \
        bhop_advi; \
    do \
        curl -fsSL --retry 3 --retry-all-errors \
            "https://main.fastdl.me/maps/${map}.bsp.bz2" \
            -o "/tmp/${map}.bsp.bz2" \
        && bzip2 -d "/tmp/${map}.bsp.bz2" \
        && mv "/tmp/${map}.bsp" "cstrike/maps/${map}.bsp" \
        || exit 1; \
    done

FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        libstdc++6 \
        tini \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash steam

COPY --from=builder --chown=steam:steam /home/steam/css-serverfiles /home/steam/css-serverfiles
COPY --from=builder --chown=steam:steam /home/steam/.steam/sdk64/steamclient.so /home/steam/.steam/sdk64/steamclient.so
COPY --chown=steam:steam docker-entrypoint.sh /home/steam/docker-entrypoint.sh
RUN chmod +x /home/steam/docker-entrypoint.sh

ENV CSS_MAP=de_dust2 \
    CSS_MAXPLAYERS=16 \
    CSS_PORT=27015 \
    CSS_TICKRATE=66

EXPOSE 27015/tcp 27015/udp 27020/udp

USER steam
WORKDIR /home/steam/css-serverfiles

ENTRYPOINT ["/usr/bin/tini", "--", "/home/steam/docker-entrypoint.sh"]

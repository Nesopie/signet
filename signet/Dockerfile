FROM ubuntu:24.04
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt update \
    && apt -y --no-install-recommends install \
    build-essential libtool autotools-dev automake pkg-config bsdmainutils python3 libevent-dev libboost-dev libsqlite3-dev jq curl -y

WORKDIR /src/bitcoin
COPY ./bitcoin .

RUN ./autogen.sh && ./configure
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && make -j20 && make install 

COPY ./setup.sh /setup.sh

WORKDIR /src/bitcoin/src

RUN chmod +x /setup.sh

EXPOSE 38332 38333 38334

ENTRYPOINT ["bash", "/setup.sh"]


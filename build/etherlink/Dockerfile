# SPDX-FileCopyrightText: 2023 Baking Bad <hello@bakingbad.dev>
#
# SPDX-License-Identifier: MIT

ARG OCTEZ_TAG
FROM tezos/tezos:${OCTEZ_TAG} AS octez

FROM ubuntu:22.04 AS builder
RUN apt-get -qq update
RUN apt-get install -y -q \
    build-essential \
    curl \
    wget \
    make \
    libc-dev \
    git \
    clang
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add wasm32-unknown-unknown
WORKDIR /build
COPY config/dev.yaml ./config/dev.yaml
COPY Makefile ./
RUN make install CARGO_BIN_PATH=/root/.cargo/bin
ARG TEZOS_REPO
ARG TEZOS_REPO_BRANCH
ARG CACHEBUST=1
RUN git clone -b ${TEZOS_REPO_BRANCH} --single-branch ${TEZOS_REPO}
RUN cd tezos && git log -1
ARG PACKAGE
ARG CI_COMMIT_SHA
RUN make build-operator PACKAGE=${PACKAGE} CI_COMMIT_SHA=${CI_COMMIT_SHA}

FROM ztepler/tezos-fabridge-bins:latest AS fa-bridge-bins

FROM ubuntu:22.04 AS etherlink
RUN apt-get -qq update && \
    apt-get install -y \
    binutils \
    gcc \
    libgmp-dev \
    libhidapi-dev \
    libc6-dev \
    libev-dev \
    libffi-dev \
    sudo \
    sqlite3 \
    libsqlite3-dev \
    xxd \
    netbase \
    wget \
    ca-certificates
COPY --from=fa-bridge-bins /usr/bin/octez-smart-rollup-node /usr/bin/octez-smart-rollup-node
COPY --from=fa-bridge-bins /usr/bin/octez-client /usr/bin/octez-client
COPY --from=fa-bridge-bins /usr/bin/octez-node /usr/bin/octez-node
COPY --from=fa-bridge-bins /usr/share/zcash-params/ /root/.zcash-params/
COPY --from=fa-bridge-bins /usr/bin/octez-evm-node /usr/bin/octez-evm-node
COPY --from=builder /build/bin/wasm_2_0_0/ /root/wasm_2_0_0/
ARG PACKAGE
COPY --from=builder /build/bin/${PACKAGE}_installer.wasm /root/kernel.wasm
COPY ./build/etherlink/entrypoint.sh .
RUN chmod +x entrypoint.sh && ln ./entrypoint.sh /usr/bin/operator
ENTRYPOINT [ "./entrypoint.sh" ]

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

FROM alpine:3.15 AS etherlink
RUN apk --no-cache add binutils gcc gmp libgmpxx hidapi libc-dev libev libffi sudo sqlite sqlite-libs sqlite-dev
ARG OCTEZ_PROTO
COPY --from=octez /usr/local/bin/octez-smart-rollup-node-${OCTEZ_PROTO} /usr/bin/octez-smart-rollup-node
COPY --from=octez /usr/local/bin/octez-client /usr/bin/octez-client
COPY --from=octez /usr/local/bin/octez-evm-node /usr/bin/octez-evm-node
COPY --from=builder /build/bin/wasm_2_0_0/ /root/wasm_2_0_0/
COPY --from=octez /usr/local/bin/octez-node /usr/bin/octez-node
COPY --from=octez /usr/share/zcash-params/ /root/.zcash-params/
ARG PACKAGE
COPY --from=builder /build/bin/${PACKAGE}_installer.wasm /root/kernel.wasm
COPY ./build/etherlink/entrypoint.sh .
RUN chmod +x entrypoint.sh && ln ./entrypoint.sh /usr/bin/operator
ENTRYPOINT [ "./entrypoint.sh" ]

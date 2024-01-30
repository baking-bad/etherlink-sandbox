# SPDX-FileCopyrightText: 2023 Baking Bad <hello@bakingbad.dev>
#
# SPDX-License-Identifier: MIT

.PHONY: test

-include envs/etherlink-nairobi.env

BIN_DIR:=$$PWD/bin
TARGET_DIR=$$PWD/target
CARGO_BIN_PATH:=$$HOME/.cargo/bin
PACKAGE=evm_kernel
CI_COMMIT_SHA=dev
INSTALLER_CONF_PATH=$$PWD/config/dev.yaml

install:
	cargo install tezos-smart-rollup-installer --locked
	cd $(CARGO_BIN_PATH) \
		&& wget -c https://github.com/WebAssembly/binaryen/releases/download/version_111/binaryen-version_111-x86_64-linux.tar.gz -O - | tar -xzv binaryen-version_111/bin/wasm-opt --strip-components 2 \
		&& wget -c https://github.com/WebAssembly/wabt/releases/download/1.0.31/wabt-1.0.31-ubuntu.tar.gz -O - | tar -xzv wabt-1.0.31/bin/wasm-strip wabt-1.0.31/bin/wasm2wat --strip-components 2

build-kernel:
	RUSTC_BOOTSTRAP=1 cargo build --manifest-path=tezos/src/kernel_evm/Cargo.toml --package $(PACKAGE) \
		--target wasm32-unknown-unknown \
		--target-dir $(TARGET_DIR) \
		--features debug,default \
		--release \
		-Z sparse-registry \
		-Z avoid-dev-deps
	wasm-strip -o $(BIN_DIR)/$(PACKAGE).wasm $(TARGET_DIR)/wasm32-unknown-unknown/release/$(PACKAGE).wasm

build-installer:
	smart-rollup-installer get-reveal-installer \
		--upgrade-to $(BIN_DIR)/$(PACKAGE).wasm \
		--output $(BIN_DIR)/$(PACKAGE)_installer.wasm \
		--preimages-dir $(BIN_DIR)/wasm_2_0_0 \
		--setup-file $(INSTALLER_CONF_PATH)

build-operator:
	mkdir $(BIN_DIR) || true
	$(MAKE) build-kernel PACKAGE=$(PACKAGE) CI_COMMIT_SHA=$(CI_COMMIT_SHA)
	$(MAKE) build-installer PACKAGE=$(PACKAGE)

image-etherlink:
	docker build -t etherlink:$(OCTEZ_TAG) --file ./build/etherlink/Dockerfile \
		--build-arg OCTEZ_TAG=$(OCTEZ_TAG) \
		--build-arg OCTEZ_PROTO=$(OCTEZ_PROTO) \
		--build-arg PACKAGE=$(PACKAGE) \
		--build-arg TEZOS_REPO=$(TEZOS_REPO) \
		--build-arg TEZOS_REPO_BRANCH=$(TEZOS_REPO_BRANCH) \
		--build-arg CI_COMMIT_SHA=$(CI_COMMIT_SHA) \
		.

run-operator:
	$(MAKE) image-etherlink \
		OCTEZ_TAG=$(OCTEZ_TAG) \
		OCTEZ_PROTO=$(OCTEZ_PROTO) \
		PACKAGE=$(PACKAGE) \
		TEZOS_REPO=$(TEZOS_REPO) \
		TEZOS_REPO_BRANCH=$(TEZOS_REPO_BRANCH) \
		CI_COMMIT_SHA=$(CI_COMMIT_SHA)
	docker stop operator || true
	docker network create etherlink-net || true
	docker run --rm -it \
		--name operator \
		--network=etherlink-net \
		--entrypoint=/bin/sh \
		-v $$PWD/.tezos-client:/root/.tezos-client/ \
		-v $$PWD/.tezos-smart-rollup-node:/root/.tezos-smart-rollup-node \
		-p 127.0.0.1:8932:8932 \
		-e NETWORK=$(NETWORK) \
		etherlink:$(OCTEZ_TAG)

run-facade:
	$(MAKE) image-etherlink \
		OCTEZ_TAG=$(OCTEZ_TAG) \
		OCTEZ_PROTO=$(OCTEZ_PROTO) \
		PACKAGE=$(PACKAGE) \
		TEZOS_REPO=$(TEZOS_REPO) \
		TEZOS_REPO_BRANCH=$(TEZOS_REPO_BRANCH) \
		CI_COMMIT_SHA=$(CI_COMMIT_SHA)
	docker stop facade || true
	docker network create etherlink-net || true
	docker run --rm -it \
		--name facade \
		--network=etherlink-net \
		--entrypoint=/usr/bin/octez-evm-node \
		-p 127.0.0.1:8545:8545 \
		etherlink:$(OCTEZ_TAG) \
                run \
				proxy \
                with \
                endpoint \
		http://operator:8932 \
		--rpc-addr "0.0.0.0" \
		--rpc-port 8545

# Etherlink build & deploy

Build and deployment scripts for Etherlink

**IMPORTANT: NOT STABLE YET, DO NOT RUN THIS CODE IN PRODUCTION**

## How to build

### Docker image

Create docker image for Nairobinet

```
make image-etherlink
```

## How to run locally

Note the environment file included in the Makefile, that exposes target `NETWORK`.

### Operator

```
make run-operator
```

You will end up inside the docker container shell.  
Every time you call this target, kernel and docker image will be rebuilt.

#### Generate new keys

For convenience, your local .tezos-client folder is mapped into the container in order to preserve the keys. Upon the first launch you need to create new keypair, in order to do that inside the operator shell:

```
$ operator generate_key
```

#### Check account info

If you already have a key, check it's balance: it should be at least 10k tez to operate a rollup, otherwise top up the balance from the faucet. To get your account address:

```
$ operator account_info
```

#### Originate rollup

```
$ operator deploy_rollup
```

Rollup data is persisted meaning that you can restart the container without data loss. If you try to call this command again it will tell you that there's an existing rollup configuration. Use `--force` flag to remove all data and originate a new one.

#### Run rollup node

```
$ operator run_node
```

Runs rollup node in synchronous mode, with logs being printed to stdout.  
Also RPC is available at `127.0.0.1:8932` on your host machine.

### Evm-node facade

```
make run-facade
```

RPC is available at `127.0.0.1:8545` on your host machine.
Every time you call this target, kernel and docker image will be rebuilt.

## Docker compose

Once you have image built, you can run services with compose.

First, create a `.env` file with four environment variables:
```
TAG=<operator image tag>
NETWORK=<destination network name>
ROLLUP_ADDRESS=<sr rollup address from node logs>
OPERATOR_KEY=unencrypted:<edsk private key from .tezos-client folder>
```

Then run docker-compose:

```
docker-compose up -d
```
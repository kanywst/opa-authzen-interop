PDP_IMAGE := ghcr.io/kanywst/opa-authzen-plugin
PDP_VERSION := latest

.PHONY: test rego-test integration-test up down clean

## Run all tests (rego unit tests + integration tests against Docker PDP)
test: rego-test integration-test

## Run Rego unit tests (no PDP required)
rego-test:
	opa test policy/ data/ -v

## Start PDP, run integration tests, then stop
integration-test: up
	./scripts/test-local.sh
	$(MAKE) down

## Start the PDP via Docker Compose
up:
	PDP_IMAGE=$(PDP_IMAGE) PDP_VERSION=$(PDP_VERSION) docker compose up -d --wait

## Stop the PDP
down:
	docker compose down

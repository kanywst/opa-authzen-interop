PDP_IMAGE := ghcr.io/kanywst/opa-authzen-plugin
# Pin to a concrete release rather than `latest`, which lags. The suite needs
# 0.6 or newer: batch evaluations and Search arrived in 0.3, capability URNs in
# the metadata document in 0.4, decision context in 0.5, and the Obligations
# Profile in 0.6 — all of which config.yaml now enables and the tests assert.
PDP_VERSION := 0.6

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

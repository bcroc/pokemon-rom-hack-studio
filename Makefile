SHELL := /bin/bash

.DEFAULT_GOAL := validate

PACKAGE_DIR := PokemonHackStudio
APP_SCRIPT := ./script/build_and_run.sh

.PHONY: build test validate validate-nds scripts-check test-app run verify

build:
	swift build --package-path $(PACKAGE_DIR)

test:
	swift test --package-path $(PACKAGE_DIR)

validate:
	./script/validate.sh

validate-nds:
	./script/validate_nds.sh

scripts-check:
	bash -n script/*.sh
	$(APP_SCRIPT) --check-tools

test-app:
	$(APP_SCRIPT) test

run:
	$(APP_SCRIPT) run

verify:
	$(APP_SCRIPT) verify

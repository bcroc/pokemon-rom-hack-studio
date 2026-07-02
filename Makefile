SHELL := /bin/bash

.DEFAULT_GOAL := validate

PACKAGE_DIR := PokemonHackStudio
APP_SCRIPT := ./script/build_and_run.sh

.PHONY: build test validate validate-nds scripts-check test-app run verify validate-synthetic validate-gba-fixtures validate-nds-strict validate-gui-smoke validate-release-candidate

build:
	swift build --package-path $(PACKAGE_DIR)

test:
	swift test --package-path $(PACKAGE_DIR)

validate:
	./script/validate.sh

validate-nds:
	./script/validate_nds.sh

validate-synthetic: scripts-check test

validate-gba-fixtures:
	REQUIRE_GBA_FIXTURES=1 ./script/validate.sh

validate-nds-strict:
	REQUIRE_NDS_REFERENCES=1 ./script/validate_nds.sh

validate-gui-smoke: test-app

validate-release-candidate: scripts-check validate validate-nds test-app verify

scripts-check:
	bash -n script/*.sh
	./script/check_validation_docs.sh
	$(APP_SCRIPT) --check-tools

test-app:
	$(APP_SCRIPT) test

run:
	$(APP_SCRIPT) run

verify:
	$(APP_SCRIPT) verify

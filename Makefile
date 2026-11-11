# My Sweet Home — Build and verification harness

SHELL := /bin/bash
ifeq ($(OS),Windows_NT)
FLUTTER ?= flutter.bat
DART ?= dart.bat
else
FLUTTER ?= flutter
DART ?= dart
endif
PY ?= python3

.DEFAULT_GOAL := help
.PHONY: help setup gen check-gen format analyze test golden arch coverage check clean

help: ## Show available make targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | expand -t24

setup: ## Install dependencies and generate code
	$(FLUTTER) pub get
	$(MAKE) gen

gen: ## Regenerate freezed, drift, and riverpod code
	@$(DART) run build_runner build --delete-conflicting-outputs

check-gen: ## Verify generated code is in sync
	@$(PY) scripts/check_staged_generated_code.py
	@$(PY) scripts/check_generated.py

format: ## Check Dart code formatting
	@$(DART) format --output=none --set-exit-if-changed lib test

analyze: ## Run static analysis and custom_lint
	@$(DART) analyze lib test
	@grep -q "custom_lint:" pubspec.yaml && $(DART) run custom_lint || true

test: ## Run unit and widget tests with coverage
	@$(FLUTTER) test --no-pub --coverage --test-randomize-ordering-seed=random --reporter=failures-only

golden: ## Run golden tests
	@$(FLUTTER) test --no-pub --tags golden --reporter=failures-only

arch: ## Run architectural compliance tests
	@$(FLUTTER) test --no-pub test/architecture --reporter=failures-only

coverage: ## Verify code coverage thresholds
	@$(PY) scripts/check_coverage.py coverage/lcov.info

check: format check-gen analyze test coverage ## Project gate: run full validation suite

clean: ## Clean build and coverage artifacts
	$(FLUTTER) clean
	rm -rf coverage .dart_tool

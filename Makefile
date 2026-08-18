IMAGE_NAME ?= srcml-dev:ubuntu24.04
CLONE_TYPE ?= type1
LIMIT ?= 100
SELECTION_ROLE ?= tuning
CASES_DIR ?= benchmarks/bigclonebench/cases

.PHONY: help docker-build docker-rebuild shell srcmove build build-dev build-release build-production test benchmark-repo bigclonebench-preflight bigclonebench-cases bigclonebench lock-status lock-verify lock-update

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-28s %s\n' 'make docker-build' 'Build the Docker image if needed'
	@printf '  %-28s %s\n' 'make docker-rebuild' 'Rebuild the Docker image after Dockerfile changes'
	@printf '  %-28s %s\n' 'make shell' 'Enter the Ubuntu dev container'
	@printf '  %-28s %s\n' 'make srcmove' 'Build srcMove and its dependencies in Docker'
	@printf '  %-28s %s\n' 'make build' 'Alias for make build-release'
	@printf '  %-28s %s\n' 'make build-dev' 'Debug build for day-to-day development'
	@printf '  %-28s %s\n' 'make build-release' 'Optimized local build'
	@printf '  %-28s %s\n' 'make build-production' 'Release/test/package build where supported'
	@printf '  %-28s %s\n' 'make test' 'Run srcMove tests in Docker'
	@printf '  %-28s %s\n' 'make benchmark-repo' 'Run and save CASE repository benchmark'
	@printf '  %-28s %s\n' 'make bigclonebench-preflight' 'Check the local BigCloneBench installation'
	@printf '  %-28s %s\n' 'make bigclonebench-cases' 'Generate a configurable BigCloneBench case slice'
	@printf '  %-28s %s\n' 'make bigclonebench' 'Generate cases and run the staged BigCloneBench pipeline'
	@printf '  %-28s %s\n' 'make lock-status' 'Compare source checkouts with workspace.lock.json'
	@printf '  %-28s %s\n' 'make lock-verify' 'Fail unless source checkouts match workspace.lock.json'
	@printf '  %-28s %s\n' 'make lock-update' 'Capture the current clean source revisions'

docker-build:
	./bin/srcml-dev-shell true

docker-rebuild:
	./bin/srcml-dev-shell --rebuild true

shell:
	./bin/srcml-dev-shell

srcmove:
	./bin/srcml-dev-shell ./bin/srcml-build-srcmove

build:
	$(MAKE) build-release

build-dev:
	./bin/srcml-dev-build-dev

build-release:
	./bin/srcml-dev-build

build-production:
	./bin/srcml-dev-build-production

test:
	./bin/srcml-dev-shell bash -lc 'cd srcMove && make test'

benchmark-repo:
	@test -n "$(CASE)" || { echo 'error: CASE is required'; exit 2; }
	./bin/srcml-dev-shell make -C srcMove benchmark-repo \
		CASE="$(CASE)" SERIES="$(SERIES)" UPDATE="$(UPDATE)" OFFLINE="$(OFFLINE)"

bigclonebench-preflight:
	./bin/srcml-dev-shell make -C srcMove bigclonebench-preflight

bigclonebench-cases:
	./bin/srcml-dev-shell make -C srcMove bigclonebench-cases \
		CLONE_TYPE="$(CLONE_TYPE)" LIMIT="$(LIMIT)" \
		SELECTION_ROLE="$(SELECTION_ROLE)" CASES_DIR="$(CASES_DIR)" \
		CANDIDATE_LIMIT="$(CANDIDATE_LIMIT)" DEDUPE="$(DEDUPE)" \
		TEXT_CHANGE="$(TEXT_CHANGE)"

bigclonebench:
	./bin/srcml-dev-shell make -C srcMove bigclonebench \
		CLONE_TYPE="$(CLONE_TYPE)" LIMIT="$(LIMIT)" \
		SELECTION_ROLE="$(SELECTION_ROLE)" CASES_DIR="$(CASES_DIR)" \
		CANDIDATE_LIMIT="$(CANDIDATE_LIMIT)" DEDUPE="$(DEDUPE)" \
		TEXT_CHANGE="$(TEXT_CHANGE)"

lock-status:
	./bin/workspace-lock status

lock-verify:
	./bin/workspace-lock verify

lock-update:
	./bin/workspace-lock capture

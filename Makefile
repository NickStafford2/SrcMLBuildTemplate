IMAGE_NAME ?= srcml-dev:ubuntu24.04

.PHONY: help docker-build docker-rebuild shell srcmove build build-dev build-release build-production test lock-status lock-verify lock-update

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-16s %s\n' 'make docker-build' 'Build the Docker image if needed'
	@printf '  %-16s %s\n' 'make docker-rebuild' 'Rebuild the Docker image after Dockerfile changes'
	@printf '  %-16s %s\n' 'make shell' 'Enter the Ubuntu dev container'
	@printf '  %-16s %s\n' 'make srcmove' 'Build srcMove and its dependencies in Docker'
	@printf '  %-16s %s\n' 'make build' 'Alias for make build-release'
	@printf '  %-16s %s\n' 'make build-dev' 'Debug build for day-to-day development'
	@printf '  %-16s %s\n' 'make build-release' 'Optimized local build'
	@printf '  %-16s %s\n' 'make build-production' 'Release/test/package build where supported'
	@printf '  %-16s %s\n' 'make test' 'Run srcMove tests in Docker'
	@printf '  %-16s %s\n' 'make lock-status' 'Compare source checkouts with workspace.lock.json'
	@printf '  %-16s %s\n' 'make lock-verify' 'Fail unless source checkouts match workspace.lock.json'
	@printf '  %-16s %s\n' 'make lock-update' 'Capture the current clean source revisions'

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

lock-status:
	./bin/workspace-lock status

lock-verify:
	./bin/workspace-lock verify

lock-update:
	./bin/workspace-lock capture

IMAGE_NAME ?= srcml-dev:ubuntu24.04

.PHONY: help docker-build docker-rebuild shell build build-dev build-release build-production test

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-16s %s\n' 'make docker-build' 'Build the Docker image if needed'
	@printf '  %-16s %s\n' 'make docker-rebuild' 'Rebuild the Docker image after Dockerfile changes'
	@printf '  %-16s %s\n' 'make shell' 'Enter the Ubuntu dev container'
	@printf '  %-16s %s\n' 'make build' 'Alias for make build-release'
	@printf '  %-16s %s\n' 'make build-dev' 'Debug build for day-to-day development'
	@printf '  %-16s %s\n' 'make build-release' 'Optimized local build'
	@printf '  %-16s %s\n' 'make build-production' 'Release/test/package build where supported'
	@printf '  %-16s %s\n' 'make test' 'Run srcMove tests in Docker'

docker-build:
	./bin/srcml-dev-shell true

docker-rebuild:
	./bin/srcml-dev-shell --rebuild true

shell:
	./bin/srcml-dev-shell

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

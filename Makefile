IMAGE_NAME ?= srcml-dev:ubuntu24.04

.PHONY: help docker-build docker-rebuild shell build test

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-16s %s\n' 'make docker-build' 'Build the Docker image if needed'
	@printf '  %-16s %s\n' 'make docker-rebuild' 'Rebuild the Docker image after Dockerfile changes'
	@printf '  %-16s %s\n' 'make shell' 'Enter the Ubuntu dev container'
	@printf '  %-16s %s\n' 'make build' 'Build srcML, srcReader, srcDiff, and srcMove in Docker'
	@printf '  %-16s %s\n' 'make test' 'Run srcMove tests in Docker'

docker-build:
	./bin/srcml-dev-shell true

docker-rebuild:
	./bin/srcml-dev-shell --rebuild true

shell:
	./bin/srcml-dev-shell

build:
	./bin/srcml-dev-build

test:
	./bin/srcml-dev-shell bash -lc 'cd srcMove && ./build_and_test'

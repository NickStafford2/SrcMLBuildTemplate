IMAGE_NAME ?= srcml-dev:ubuntu24.04
PROFILE ?= small
ROLE ?= tuning
SEED ?= 0
VERIFY_SOURCE ?= 0

.PHONY: help docker-build docker-rebuild shell srcmove build build-dev build-release build-production test history-scaling srcvisual-eval-check srcvisual-eval-fast srcvisual-eval-400 srcvisual-image-rebuild srcvisual-history-refresh bigmovebench-preflight bigmovebench-suite lock-status lock-verify lock-update

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
	@printf '  %-28s %s\n' 'make history-scaling' 'Measure srcMove History throughput across JOBS'
	@printf '  %-28s %s\n' 'make srcvisual-eval-check' 'Build and verify the mounted srcMove binary; run no analysis'
	@printf '  %-28s %s\n' 'make srcvisual-eval-fast' 'Evaluate a small Notepad++ sample (default: 10 pairs)'
	@printf '  %-28s %s\n' 'make srcvisual-eval-400' 'Evaluate the fixed 400-pair Notepad++ set'
	@printf '  %-28s %s\n' 'make srcvisual-image-rebuild' 'Rebuild the full srcVisual image'
	@printf '  %-28s %s\n' 'make bigmovebench-preflight' 'Check the local BigCloneBench installation'
	@printf '  %-28s %s\n' 'make bigmovebench-suite' 'Run BigMoveBench PROFILE=small|medium (full is slow)'
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

history-scaling:
	@./bin/srcml-dev-shell make --no-print-directory -C srcMove history-scaling \
		CASE="$(CASE)" START="$(START)" COUNT="$(COUNT)" JOBS="$(JOBS)" \
		REPETITIONS="$(REPETITIONS)" WARMUPS="$(WARMUPS)" SEED="$(SEED)" \
		LABEL="$(LABEL)" ENVIRONMENT_LABEL="$(ENVIRONMENT_LABEL)" \
		SCRATCH_ROOT="$(SCRATCH_ROOT)" DIRECTORY="$(DIRECTORY)" \
		UPDATE="$(UPDATE)" OFFLINE="$(OFFLINE)"

SRCVISUAL_JOBS ?= 8
SRCVISUAL_FAST_PAIRS ?= 10
SRCVISUAL_REBUILD_ARG = $(if $(filter 1 yes true,$(FULL_REBUILD)),--rebuild-image,)

srcvisual-eval-check:
	./bin/srcvisual-history-refresh --check $(SRCVISUAL_REBUILD_ARG)

srcvisual-eval-fast:
	./bin/srcvisual-history-refresh --pairs "$(SRCVISUAL_FAST_PAIRS)" --jobs "$(SRCVISUAL_JOBS)" $(SRCVISUAL_REBUILD_ARG)

srcvisual-eval-400:
	./bin/srcvisual-history-refresh --pairs 400 --jobs "$(SRCVISUAL_JOBS)" $(SRCVISUAL_REBUILD_ARG)

srcvisual-image-rebuild:
	docker compose -f srcVisual/compose.yaml build srcvisual

# Backward-compatible name for the fixed research evaluation.
srcvisual-history-refresh: srcvisual-eval-400

bigmovebench-preflight:
	@./bin/srcml-dev-shell make --no-print-directory -C srcMove bigmovebench-preflight

bigmovebench-suite:
	@./bin/srcml-dev-shell make --no-print-directory -C srcMove bigmovebench-suite \
		PROFILE="$(PROFILE)" ROLE="$(ROLE)" PAIR_SET="$(PAIR_SET)" \
		VERIFY_SOURCE="$(VERIFY_SOURCE)"

lock-status:
	./bin/workspace-lock status

lock-verify:
	./bin/workspace-lock verify

lock-update:
	./bin/workspace-lock capture

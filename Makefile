# Makefile for building the lab-assign Docker image
# Usage:
#   make build-image                 # build with latest base (uses --pull)
#   make build-image JULIA_VERSION=1.11  # pin specific Julia version
#   make solve CSV=all-avail.csv     # solve a specific test case

IMAGE_NAME ?= lab-assign
PULL ?= --pull
JULIA_VERSION ?=
CSV ?= lab-pref.csv

.PHONY: build-image
build-image:
	docker build $(PULL) $(if $(JULIA_VERSION),--build-arg JULIA_VERSION=$(JULIA_VERSION),) -t $(IMAGE_NAME) .

.PHONY: solve
solve:
	docker run --rm -v "$$(pwd)":/files $(IMAGE_NAME):latest julia /files/assign.jl /files/$(CSV)

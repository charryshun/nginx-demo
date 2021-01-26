SHELL=/bin/bash
REGISTRY?=simonzhaohui
REGISTRY_TOKEN?=dev

BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%TZ")

# populated by Jenkins
APP=nginx-hello
BRANCH_NAME?=dev
EPOCH?=dev

VERSION?=0.0.1
IMAGE_NAME:=${REGISTRY}/${APP}
IMAGE_LATEST:=${IMAGE_NAME}:latest
IMAGE_TAG=${VERSION}-${BRANCH_NAME}-${EPOCH}
IMAGE:=${IMAGE_NAME}:${IMAGE_TAG}

.DEFAULT: build

PHONY: build
build: login image push

.PHONY: login
login:
	docker login -u simonzhaohui --password ${REGISTRY_TOKEN}

# Build an operator image for deployment
.PHONY: image
image:
	@echo "generated from branch ${BRANCH_NAME}" >> nginx-hello/index.html
	docker build . \
	-f ./nginx-hello/Dockerfile \
	-t ${IMAGE} \
	--pull \
	--no-cache

.PHONY: push
push:
	docker push ${IMAGE}

# Jenkins support
# fetch image name and tag
.PHONY: fetch-image-tag
fetch-image-tag:
	@echo ${IMAGE_TAG}

.PHONY: fetch-image-name
fetch-image-name:
	@echo ${IMAGE_NAME}

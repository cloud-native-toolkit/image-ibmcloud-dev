#!/usr/bin/env bash

SCRIPT_DIR=$(dirname $0)

REGISTRY_NAME="$1"
IMAGE_NAME="$2"
IMAGE_VER="$3"
IMAGE_TAG="$4"

if [[ -z "${REGISTRY_NAME}" ]] || [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
  echo "Usage: $0 {REGISTRY_NAME} {IMAGE_NAME} {IMAGE_VER} [{IMAGE_TAG}]"
  exit 1
fi

if [[ -n "${IMAGE_TAG}" ]]; then
  IMAGE_VER="${IMAGE_VER}-${IMAGE_TAG}"
fi

docker tag "${IMAGE_NAME}:${IMAGE_VER}" "${REGISTRY_NAME}/${IMAGE_NAME}:${IMAGE_VER}"
docker push "${REGISTRY_NAME}/${IMAGE_NAME}:${IMAGE_VER}"

if [[ -z "${IMAGE_TAG}" ]]; then
  docker tag "${IMAGE_NAME}:${IMAGE_VER}" "${REGISTRY_NAME}/${IMAGE_NAME}:latest"
  docker push "${REGISTRY_NAME}/${IMAGE_NAME}:latest"
fi

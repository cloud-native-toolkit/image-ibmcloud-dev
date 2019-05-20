#!/usr/bin/env bash

IMAGE_NAME="$1"
IMAGE_VER="$2"
IMAGE_TAG="$3"

if [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
  echo "Usage: $0 {IMAGE_NAME} {IMAGE_VER} [{IMAGE_TAG}]"
  exit 1
fi

if [[ -n "${IMAGE_TAG}" ]]; then
  IMAGE_VER="${IMAGE_VER}-${IMAGE_TAG}"
fi

docker build -t "${IMAGE_NAME}:${IMAGE_VER}" .

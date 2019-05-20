#!/usr/bin/env bash

IMAGE_ORG="$1"
IMAGE_NAME="$2"
IMAGE_VER="$3"
IMAGE_TAG="$4"

if [[ -z "${IMAGE_ORG}" ]] || [[ -z "${IMAGE_NAME}" ]] || [[ -z "${IMAGE_VER}" ]]; then
   echo "Required input is missing"
   echo "Usage: $0 {IMAGE_ORG} {IMAGE_NAME} {IMAGE_VER} [{IMAGE_TAG}]"
   exit 1
fi

if [[ -n "${IMAGE_TAG}" ]]; then
  IMAGE_VER="${IMAGE_VER}-${IMAGE_TAG}"
fi

echo "Pulling and tagging ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}"

docker pull ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER}
docker tag ${IMAGE_ORG}/${IMAGE_NAME}:${IMAGE_VER} ${IMAGE_NAME}:${IMAGE_VER}

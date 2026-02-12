#!/bin/bash
set -euo pipefail

IMAGE_NAME="${1:-fifty-first-contexts}"
TAG="${2:-latest}"

docker build -t "${IMAGE_NAME}:${TAG}" "$(dirname "$0")"

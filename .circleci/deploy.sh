#!/usr/bin/env bash

set -e
set -u
set -o pipefail

git config user.name CircleCI
git config user.email <>
git add -A docs
git commit -m '[skip ci] Update docs'
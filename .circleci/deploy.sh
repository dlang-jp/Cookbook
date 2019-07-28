#!/usr/bin/env bash

set -e
set -u

git config user.name CircleCI
git config user.email <>
git add -A docs
git commit -m '[skip ci] Update docs'
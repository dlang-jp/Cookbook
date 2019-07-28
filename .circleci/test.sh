#!/usr/bin/env bash

set -e
set -u

source "$(curl -fsS https://dlang.org/install.sh | bash -s $1 --activate)"

dub test
dub build --build=docs

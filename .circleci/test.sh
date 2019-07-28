#!/usr/bin/env bash

set -e
set -u

source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s dmd --activate)"

dub test
dub build --build=docs

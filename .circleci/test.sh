#!/usr/bin/env bash

set -e
set -u
set -o pipefail

source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"
dub test
cat dub.selections.json

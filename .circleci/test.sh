#!/usr/bin/env bash

set -e
set -u

source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"

dub test
dub test :windows
dub test :libdparse_usage

#!/usr/bin/env bash

set -e
set -u

source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"

dub test
dub test :asdf_usage
dub test :botan_usage
dub test :libdparse_usage
dub test :vibe-d_usage
dub test :windows

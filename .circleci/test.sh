#!/usr/bin/env bash

set -e
set -u

curl https://dlang.org/install.sh | bash -s
source "$(~/dlang/install.sh dmd -a)"

dub test
dub build --build=docs

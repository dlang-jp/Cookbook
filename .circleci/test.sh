#!/usr/bin/env bash

set -e
set -u

curl https://dlang.org/install.sh | bash -s
source ~/dlang/dmd-2.087.0/activate

dub test
dub build --build=docs

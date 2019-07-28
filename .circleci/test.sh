#!/usr/bin/env bash

curl -fsS https://dlang.org/install.sh | bash -s dmd
source $(~/dlang/install.sh dmd -a)
dub test
dub build --build=docs

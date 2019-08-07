#!/usr/bin/env bash

set -e
set -u

git config --global push.default simple
git config --global user.name "CircleCI"
git config --global user.email "<>"
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"

dub build --build=ddox
rsync -ar docs ../

git checkout gh-pages
rsync -ar ../docs ./
git add -A --force .
git commit -m "[skip ci] Update docs"
git push origin gh-pages

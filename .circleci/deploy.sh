#!/usr/bin/env bash

set -e
set -u

git config --global push.default simple
git config --global user.name "CircleCI"
git config --global user.email "<>"
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
source "$(curl -fsS  --retry 3 https://dlang.org/install.sh | bash -s $1 --activate)"

# ドキュメント生成のテストは行うが、デプロイはGitHub Actionsが行う
dub run gendoc@0.0.4 -y
#mv docs ../
#
#git checkout gh-pages
#rm -r *
#mv ../docs/* ./
#git add -A --force .
#git diff-index --quiet HEAD || git commit -m "[skip ci] Update docs"
#git push origin gh-pages

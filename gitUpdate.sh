#! /bin/sh
PARENT_PATH=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
cd "$PARENT_PATH"

git fetch origin
git reset --hard origin/main
#!/usr/bin/env bash

GIT_DIR=$(git rev-parse --git-dir)

rm -r $GIT_DIR/hooks/pre-commit 2>/dev/null

# create symlink to the pre-commit script
ln -s ../../scripts/pre-commit.sh $GIT_DIR/hooks/pre-commit

echo "Git hooks set up!"

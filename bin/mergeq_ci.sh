#!/bin/bash
set -e
action=$1

function print_usage_and_exit {
  echo "Usage: mergeq_ci <merge|push> [target-branch]"
  exit 1
}

function status {
  echo "// $1"
}

function checkout_target_branch {
  status "Checking out $target_branch..."
  git fetch origin $target_branch
  git checkout -q -f FETCH_HEAD
  git log -1
  status "Cleaning up working directory..."
  git reset --hard
  git clean -df
  git log -1
}

function merge_branch_into_target_branch {
  # This ends up looking like a new merge regardless
  # of whether or not we can fast forward merge.
  # and it copies over any merge conflict resolutions.
  # It's clearly black magic.
  status "Merging $head into $target_branch..."
  git merge --no-ff --no-commit $head
  status "Updating MERGE_HEAD to $merge_head..."
  echo $merge_head > .git/MERGE_HEAD
  git status
}

function commit_merge {
  message=`git log -1 --pretty=%s $head`
  status "Committing merge ($message)..."
  git commit -m "$message"
  git log -1
}

function merge {
  status "Starting merge (on `git rev-parse HEAD`)..."
  head=`git rev-parse HEAD^2`
  merge_head=`git rev-parse HEAD^2^2`

  checkout_target_branch
  merge_branch_into_target_branch
  commit_merge
}

function push {
  status "Pushing to $target_branch..."
  git push origin HEAD:$target_branch
  git log -1
}

target_branch=${2:-"integration"}

if [ "$action" = "merge" ] ; then
  merge
elif [ "$action" = "push" ] ; then
  push
else
  print_usage_and_exit
fi

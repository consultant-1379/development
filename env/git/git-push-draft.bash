#!/bin/bash

#New parameter $2 for git-push-draft:
#-If $2 is empty/null, then git-push-draft to HEAD
#-If $2 has a value, then git-push-draft to that value (must be a valid commit)

git push origin ${2:-HEAD}:refs/drafts/$1


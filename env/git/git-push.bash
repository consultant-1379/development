#!/bin/bash

#New parameter $2 for git-push:
#-If $2 is empty/null, then git-push to HEAD
#-If $2 has a value, then git-push to that value (must be a valid commit)

git push origin ${2:-HEAD}:refs/publish/$1


#!/bin/bash

# $1 the branch
# $2 the topic
#-If $3 is empty/null, then git-push to HEAD
#-If $3 has a value, then git-push to that value (must be a valid commit)

git push origin ${3:-HEAD}:refs/for/$1/$2



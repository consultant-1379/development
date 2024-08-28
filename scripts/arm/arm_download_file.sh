#!/usr/bin/env bash

usage() {
    echo "Download a file from to Artifactory"
    echo "Usage: $0 localPath urlRepository tgtRepoFolder fileName"
    exit 1
}

if [ -z "$4" ]; then
    usage
fi

localPath=$1
urlRepository=$2
tgtRepoFolder=$3
fileName=$4

if [ ! -d "${localPath}" ]; then
    echo "ERROR: local Directory ${localPath} does not exists!"
    exit 1
fi

wget --proxy=off -x -r -nH -nc -q \
           --header="X-JFrog-Art-Api: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC" \
           -R html,md5,sha1 \
           --cut-dirs=2 \
           --directory-prefix=${localPath} \
           ${urlRepository}/${tgtRepoFolder}/${fileName}

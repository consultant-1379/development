#!/usr/bin/env bash

usage() {
    echo "Recursively deploys folder content. Attempt checksum deploy first to optimize upload time"
    echo "Usage: $0 localDirectory urlRepository tgtRepoFolder"
    exit 1
}

if [ -z "$3" ]; then
    usage
fi

localDirectory="$1"
urlRepository="$2"
tgtRepoFolder="$3"
# TODO: use API Key instead of user+pwd
# API Key: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC
artifactoryUser=esdccci
artifactoryPass=Pcdlcci1

if [ -z "$localDirectory" ]; then echo "Please specify a directory to recursively upload from!"; exit 1; fi
if [ ! -x "`which sha1sum`" ]; then echo "You need to have the 'sha1sum' command in your path."; exit 1; fi

which md5sum || exit $?
which sha1sum || exit $?

# Upload by checksum all files from the source dir to the target repo
find "$localDirectory" -type f | sort | while read f; do
    rel="$(echo "$f" | sed -e "s#$localDirectory##" -e "s# /#/#")";
    md5=$(md5sum "$f")
    md5="${md5:0:32}"
    sha1=$(sha1sum "$f")
    sha1="${sha1:0:40}"
    printf "\n\nUploading '$f' \n\t(cs=${sha1}) (md5=${md5})  \n\tTo '${urlRepository}/${tgtRepoFolder}/${rel}'\n"
    status=$(curl -k -X PUT \
        -H "X-Checksum-Deploy:true" \
        -H "X-Checksum-Md5:$md5" \
        -H "X-Checksum-Sha1:$sha1" \
        -H "X-JFrog-Art-Api: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC" \
        --write-out %{http_code} --silent --output /dev/null \
        "${urlRepository}/${tgtRepoFolder}/${rel}")
    echo "STATUS=$status"
    # No checksum found - deploy + content
    [ ${status} -eq 404 ] && {
        curl -k \
            -H "X-Checksum-Md5:$md5" \
            -H "X-Checksum-Sha1:$sha1" \
            -H "X-JFrog-Art-Api: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC" \
            -T "$f" \
            "${urlRepository}/${tgtRepoFolder}/${rel}"
    }
done

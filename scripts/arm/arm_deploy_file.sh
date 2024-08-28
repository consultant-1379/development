#!/usr/bin/env bash

usage() {
    echo "Deploy a local file to Artifactory keeping the same file name"
    echo "Usage: $0 localFilePath urlRepository tgtRepoFolder"
    exit 1
}

if [ -z "$3" ]; then
    usage
fi

localFilePath=$1
urlRepository=$2
tgtRepoFolder=$3

if [ ! -f "${localFilePath}" ]; then
    echo "ERROR: local file ${localFilePath} does not exists!"
    exit 1
fi

which md5sum || exit $?
which sha1sum || exit $?

md5Value="`md5sum "${localFilePath}"`"
md5Value="${md5Value:0:32}"
sha1Value="`sha1sum "${localFilePath}"`"
sha1Value="${sha1Value:0:40}"
fileName="`basename "${localFilePath}"`"

echo "INFO: Uploading ${md5Value} ${sha1Value} ${localFilePath}"

echo "Uploading ${localFilePath}"
echo "          (cs=${sha1Value}) (md5=${md5Value})"
echo "          To ${urlRepository}/${tgtRepoFolder}/${fileName}"
status=$(curl -k -X PUT \
             -H "X-Checksum-Deploy:true" \
             -H "X-Checksum-Md5: $md5Value" \
             -H "X-Checksum-Sha1: $sha1Value" \
             -H "X-JFrog-Art-Api: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC" \
                        --write-out %{http_code} --silent --output /dev/null \
                        "${urlRepository}/${tgtRepoFolder}/${fileName}")
echo "STATUS=$status"
#if [ ${status} -eq 404 ] || [ ${status} -eq 403 ]
[ ${status} -eq 404 ] && {
    curl -k \
        -H "X-Checksum-Md5: $md5Value" \
        -H "X-Checksum-Sha1: $sha1Value" \
        -H "X-JFrog-Art-Api: AKCp2Vp5EaaM2G2zxgz2ojmPgiuVVNq7Yx622ovkKL4zKh37AvZhevHfdyyUybhazrQuoGJiC" \
        -T "${localFilePath}" \
        "${urlRepository}/${tgtRepoFolder}/${fileName}"
}

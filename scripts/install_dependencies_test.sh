#!/usr/bin/env bash

__usage()
{
   cat <<EOF
Install the consul binary into a container
Usage: ${BASH_SOURCE[0]} <file> <pattern>

file              Requirements file
pattern           element which dependencies will be installed for
EOF
}

function parse_yaml() {
local prefix=$2
local s='[[:space:]]*' w='[a-zA-Z0-9_-]*' fs=$(echo @|tr @ '\034')
sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
-e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
awk -F$fs '{
indent = length($1)/2;
vname[indent] = $2;
for (i in vname) {if (i > indent) {delete vname[i]}}
if (length($3) > 0) {
vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
printf("%s%s%s=%s\n", "'$prefix'",vn, $2, $3);
}
}'
}

# argument parameters

if [ -z "$2" ]; then
    __usage
    exit -1
fi

# cat /etc/os-release
#value=`cat config.txt`
#to obtain ID="rhel"
value=$(sed '3q;d' /etc/os-release)
OS=$(echo $value| cut -d'=' -f 2)

if [[ $OS = "ubuntu" ]]; then
   if ping -c 1 www-proxy.ericsson.se; then
      echo "Proxied environment, setting proxy variables"
      export HTTP_PROXY="http://www-proxy.ericsson.se:8080"
      export HTTPS_PROXY="http://www-proxy.ericsson.se:8080"
      export NO_PROXY="localhost,127.0.0.1,*ericsson.com*,*ericsson.net*,*ericsson.se*"
   fi
   apt-get update
   for line in $(parse_yaml $1 "" | grep $2 | sed "s/^$2__//"); do
      apt-get install -y $line
   done
else
   #microdnf update
   for line in $(parse_yaml $1 "" | grep $2 | sed "s/^$2__//"); do
      microdnf install $line
      echo $line
   done
fi



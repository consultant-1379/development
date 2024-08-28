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

OS=$(sed -e '/^ID=/,//!d' /etc/os-release | grep "^ID=" | cut -d "=" -f2)
echo "The operating system ==>> ${OS}"
if [ ${OS} = "ubuntu" ] || [ ${OS} = "debian" ]; then
   apt-get update
   for pkg in $(parse_yaml $1 "" | grep $2 | sed "s/^$2__//"); do
      echo "Package ==>> ${pkg}"
      version=$(echo ${pkg} | cut -d "=" -f2)
      if [ ${version} = "latest" ]; then
         new_pkg=$(echo ${pkg} | cut -d "=" -f1)
         echo "New Package ==>> ${new_pkg}"
         apt-get install -y ${new_pkg}
      else
         apt-get install -y ${pkg}
      fi
   done
elif [ ${OS} = "rhel" ]; then
   #microdnf update
   for pkg in $(parse_yaml $1 "" | grep $2 | sed "s/^$2__//"); do
      echo "Package ==>> ${pkg}"
      version=$(echo ${pkg} | cut -d "=" -f2)
      if [ ${version} = "latest" ]; then
         new_pkg=$(echo ${pkg} | cut -d "=" -f1)
         echo "New Package ==>> ${new_pkg}"
         microdnf install ${new_pkg}
      else
         microdnf install ${pkg}
      fi
   done
else
   echo "--------------------------------------------------------------------------------------------------------"
   echo "$(date) [$(basename ${0})] ERROR: The operating system [${OS}] is not supported."
   echo "--------------------------------------------------------------------------------------------------------"
fi

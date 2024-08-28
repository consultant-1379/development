#!/usr/bin/env bash

if ping -c 1 www-proxy.ericsson.se; then
  echo "Proxied environment, setting proxy variables"
  export http_proxy="http://www-proxy.ericsson.se:8080"
  export HTTP_PROXY="http://www-proxy.ericsson.se:8080"
  export https_proxy="http://www-proxy.ericsson.se:8080"
  export HTTPS_PROXY="http://www-proxy.ericsson.se:8080"
  export NO_PROXY="localhost,127.0.0.1,*ericsson.com*,*ericsson.net*,*ericsson.se*"
fi

apt-get update
apt-get install -y git vim 
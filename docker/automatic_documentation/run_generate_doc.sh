#!/usr/bin/env bash
normal=$'\e[0m'         # (works better sometimes)
bold=$(tput bold)       # make colors bold/bright
green=$(tput setaf 2)   # dim green text

cd /home/scripts
export PATH=$PATH:/home/scripts
clear
echo "${green}"
echo "+--------------------------+"
echo "| GENERATING DOCUMENTATION |"
echo "+--------------------------+"
echo "${normal}"

python generate_docs.py
rc=$?

if [ ${rc} -eq 0 ]; then
    echo "${green}"
    echo "+-----------------------------------+"
    echo "| UPLOADING DOCUMENTATION TO OpenALM|"
    echo "+-----------------------------------+"
    echo "${normal}"

    python upload_documents.py

    echo "${green}"
    echo "DONE"
    echo "${normal}"
fi


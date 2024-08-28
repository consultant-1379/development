#!/bin/bash -x

#########################################################
# Utility Functions to export outside the setup.sh scope
#########################################################

function __clear_var_install_python_dev_5gcicd()
{
   unset PYTHON_TYPE_INSTALLATION
   unset PYTHON_MODE_INSTALL
   unset PYTHON_INSTALL
   unset PYTHON_PACKAGES_DIR
   unset PYENV_ROOT
   unset DOWNLOAD_PYTHON
   unset ERICSSON_NETWORK
}

function __setup_root_project_dir_dev_5gcicd()
{
   cd "$( dirname "${BASH_SOURCE[0]}" )" 2>&1 >/dev/null
   pushd . 2>&1 >/dev/null
   export DEV_5GCICD_ROOT="`pwd`"
   if [ ! -d ${DEV_5GCICD_ROOT} ]
   then
       mkdir ${DEV_5GCICD_ROOT}
   fi
   popd 2>&1 >/dev/null
}

############################
# Internal Setup Functions #
############################

__setup_prompt_dev_5gcicd()
{
   __status "Setting up prompt..."

   local        BLUE="\[\033[0;34m\]"
   local        CYAN="\[\033[0;36m\]"
   local         RED="\[\033[0;31m\]"
   local   LIGHT_RED="\[\033[1;31m\]"
   local       GREEN="\[\033[0;32m\]"
   local LIGHT_GREEN="\[\033[1;32m\]"
   local       WHITE="\[\033[1;37m\]"
   local  LIGHT_GRAY="\[\033[0;37m\]"
   local     DEFAULT="\[\033[0m\]"
   PS1="\u@\h:[\W]$CYAN [\$(__parse_git_branch_prompt)] $DEFAULT\$ "

   local prompt_file="$1"
   [ "$prompt_file" = "" ] && prompt_file=~/.cicd5g-dev_custom_prompt

   if [ -f ${prompt_file} ]
   then
      export PS1=`grep -v "#" $prompt_file`
   else
      # Default CICD/5G Dev project prompt:
      export PS1="\u@\h:[\W]$CYAN [\$(__parse_git_branch_prompt)] $DEFAULT\$ "
  fi
  __status "Done. Setup prompt"
}

__setup_git_dev_5gcicd()
{
   __status "Setting up git..."

   # Bash completion for git
   . ${DEV_5GCICD_ROOT}/env/git/completion.bash
   . ${DEV_5GCICD_ROOT}/env/git/config

   ####################
   # installing hooks #
   ####################

   # git for appending Change-Id to commit logs (required for Gerrit)
   mkdir -p ${DEV_5GCICD_ROOT}/.git/hooks
   if [ ! -f "${DEV_5GCICD_ROOT}/.git/hooks/commit-msg" ]; then
      if [ ! -f ${DEV_5GCICD_ROOT}/env/git/hooks/commit-msg ]; then
         scp -q -p -P 29418 ${ERICSSON_SIGNUM}@gerrit.ericsson.se:hooks/commit-msg ${DEV_5GCICD_ROOT}/env/git/hooks/
      fi
   fi
   # CICD/5G Dev HOOKS
   cp -f ${DEV_5GCICD_ROOT}/env/git/hooks/* ${DEV_5GCICD_ROOT}/.git/hooks
   __status "Done. Setup git"
}

function __setup_arm_docker_dev_5gcicd()
{
   __status "Setting up Arm Docker Environment Variables .."
   if [ "${HTTPS_PROTOCOL}" = "true" ]; then
      export ARM_DOCKER_HTTP_PROTOCOL=https
      export ARM_DOCKER_USER=esdccci
      export ARM_DOCKER_PASS=Pcdlcci1
   else
      export ARM_DOCKER_HTTP_PROTOCOL=http
      export ARM_DOCKER_USER=
      export ARM_DOCKER_PASS=
   fi
   __status "Done. Setup Arm Docker Environment Variables."
}

function __setup_bash_dev_5gcicd()
{
   __status "Setting up bash..."
   alias git-push='${DEV_5GCICD_ROOT}/env/git/git-push.bash'
   alias git-push-draft='${DEV_5GCICD_ROOT}/env/git/git-push-draft.bash'
   alias git-push-topic='${DEV_5GCICD_ROOT}/env/git/git-push-topic.bash'
   export PATH="${DEV_5GCICD_ROOT}/bin:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/code/jenkins_check:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/deployments:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/deployments/kubernetes:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/scripts/:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/scripts/arm:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/scripts/formatter/json:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/scripts/formatter/xml:${PATH}"
   export PATH="${DEV_5GCICD_ROOT}/scripts/formatter/yaml:${PATH}"
   export URL_ARM_5GCICD_DEV_GENERIC="https://arm.lmera.ericsson.se/artifactory/proj-5g-cicd-generic-local"
   __status "Done Setup bash..."
}

function __add_modules_deps_dev_5gcicd()
{
   __status "Adding the python dependencies .."
   # Add code, utility libraries and test modules to PYTHONPATH
   cd ${DEV_5GCICD_ROOT}/code/
   ./setup.py develop
   ./setup.py sdist
   cd ${DEV_5GCICD_ROOT}/lib/
   ./setup.py develop
   ./setup.py sdist
   cd ${DEV_5GCICD_ROOT}
   __status "Done. Added the python dependencies .."
}

function __setup_python_dev_5gcicd()
{
   __status "Setting up python ..."
   [[ "${PYTHON_INSTALL}" = "true" ]] && { rm -rf ${PYENV_ROOT}; }
   __info "PYTHON_MODE_INSTALL: ${PYTHON_MODE_INSTALL}"
   __info "PYENV_ROOT:          ${PYENV_ROOT}"
   __info "ERICSSON_NETWORK:    ${ERICSSON_NETWORK:-<empty>}"
   __info "DOWNLOAD_PYTHON:     ${DOWNLOAD_PYTHON:-<empty>}"
   __info "HTTPS_PROTOCOL:      ${HTTPS_PROTOCOL}"
   . ${DEV_5GCICD_ROOT}/env/setup/setup_install_python.sh -p ${PYTHON_MODE_INSTALL} -py ${PYENV_ROOT} ${ERICSSON_NETWORK} ${DOWNLOAD_PYTHON}
   # Delete python-build logs in case it remains
   if [ -z "${USER}" ]; then
      find /tmp/ -maxdepth 1 -name "python-*" -user ${USER} -exec rm -rf {} \;
   fi
   export PYTHONPATH="${PYTHONPATH}:${DEV_5GCICD_ROOT}"
   __status "Done. Setting up python"
}

function __enable_proxy_ericsson_dev_5gcicd()
{
   __status "Enabling HTTP proxy..."
   export http_proxy="http://www-proxy.ericsson.se:8080"
   export HTTP_PROXY=${http_proxy}
   export https_proxy=${http_proxy}
   export HTTPS_PROXY=${http_proxy}
   export no_proxy="ericsson.com,ericsson.net,ericsson.se,localhost,127.0.0.1"
   __status "Done. Enabled HTTP proxy"
}

function __disable_proxy_ericsson_dev_5gcicd()
{
   __status "Disabling HTTP proxy..."
   export http_proxy=""
   export HTTP_PROXY=""
   export https_proxy=""
   export HTTPS_PROXY=""
   export no_proxy=""
   __status "Done. Disabled HTTP proxy"
}

function __set_signum_ericsson_dev_5gcicd()
{
   __status "Setting the ericsson signum..."
   local user_name=$(git config --list | grep "user.name" | cut -d "=" -f2)
   if [ ! -z "${user_name}" ] && [ ${#user_name} -eq 7 ] &&
      ([ ${user_name:0:1} = "e" ] || [ ${user_name:0:1} = "x" ]); then
      __info "user_name: [${user_name}] ==>> ERICSSON_SIGNUM"
      export ERICSSON_SIGNUM=${user_name}
   else
      local user_id=$(git config --list | grep "user.signum" | cut -d "=" -f2)
      if [ ! -z "${user_id}" ]; then
         __info "user_id: [${user_id}] ==>> ERICSSON_SIGNUM"
         export ERICSSON_SIGNUM=${user_id}
      else
         local gerrit_user_id=$(git config --list | grep "remote.origin.url" | cut -d "/" -f3 | cut -d "@" -f1)
         __info "gerrit_user_id: [${gerrit_user_id}] ==>> ERICSSON_SIGNUM"
         export ERICSSON_SIGNUM=${gerrit_user_id}
      fi
   fi
}

function __setup_clone_submodule_dev_5gcicd()
{
   __status "Executing setup clone jenkins repository..."
   __status "Check if Jenkins submodule exist"
   mkdir -p ${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod
   if [ -d ${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod/.git ]
   then
      __info "Submodule adp-cicd-jenkins-mod Already exists"
      __info "Pulling adp-cicd-jenkins-mod submodule..."
      cd ${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod
      git pull
      cd ${DEV_5GCICD_ROOT}
   else
      __info "Deleting jenkins submodule if it exixts: ${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod/ "
      rm -rf ${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod/
      __info "Cloning jenkins submodule adp-cicd-jenkins-mod"
      git clone --recursive ssh://${ERICSSON_SIGNUM}@gerrit.ericsson.se:29418/adp-cicd/jenkins.git adp-cicd-jenkins-mod
   fi
   export ADP_CICD_JENKINS_ROOT=${DEV_5GCICD_ROOT}/adp-cicd-jenkins-mod/
   __status "Done. Executed setup clone jenkins repository..."
}

function __set_branch_ericsson_dev_5gcicd()
{
   __status "Setting the ericsson branch..."
   export ERICSSON_BRANCH=$(__parse_git_branch_prompt)
}

# main setup function
__setup_project()
{
   __status "Setting CICD/5G Dev Dev Environment..."
   __set_signum_ericsson_dev_5gcicd
   mkdir -p /tmp/${ERICSSON_SIGNUM}
   __setup_clone_submodule_dev_5gcicd
   __set_branch_ericsson_dev_5gcicd
   __setup_git_dev_5gcicd
   __setup_prompt_dev_5gcicd
   __setup_bash_dev_5gcicd
   __setup_arm_docker_dev_5gcicd

   if [ "${ERICSSON_PROXY}" = "true" ]; then
      __info "USE ERICSSON PROXY: true"
      __enable_proxy_ericsson_dev_5gcicd
   else
      __info "USE ERICSSON PROXY: false"
      __disable_proxy_ericsson_dev_5gcicd
   fi

   if [ ! -z "${PYTHON_MODE_INSTALL}" ]; then
      __setup_python_dev_5gcicd
      __add_modules_deps_dev_5gcicd
   fi
   __status "Done. Set CICD/5G Dev Dev Environment."
}

function __init_setup_project_dev_5gcicd()
{
   __setup_root_project_dir_dev_5gcicd
   . ${DEV_5GCICD_ROOT}/env/setup/common_shell_func.sh
}

__show_help_dev_5gcicd()
{
   cat <<EOF
Setting up the Service Discovery enviroment
Usage: source ${BASH_SOURCE[0]} [OPTION 1] [OPTION 2] ... [OPTION N]

If no arguments are given, ${BASH_SOURCE[0]} will use the last saved configuration.
If it can not find an old configuration it will fail and ask the user to specify the configuration.

-h,  --help                        Display this help and exit.
-i,  --install                     Install the python environment. If it exists, the script will reinstall it.
-py, --python [INSTALL_MODE]       The python environment is installed. Default value is development.
                                   Installation Modes: <development/production/security>.
--http                             Use the http protocol instead of https.
-d,  --download                    Download python and the packages dependences.
-ne, --no_ericsson                 Install packages without using ericsson network.
-p,  --proxy                       Install packages using ericsson proxy (if not specified, do not use it)
-o,  --offline <PACKAGE_DIR>       The installation is done offline and this is the python package directory (absolute path).
                                   If PACKAGE_DIR is not defined, the script will use the default value.
                                    - Default Value: </tsp/BBSC/portable-tools/python_repo/>.
EOF
}


#############
# EXECUTION #
#############

# Check own shell execution (preffixed with dot or source)
[[ x"${BASH_SOURCE[0]}" = x"$0" ]] && { echo "This script must be executed 'sourced' !"; exit 1; }

PYTHON_TYPE_INSTALLATION=online
PYTHON_PACKAGES_DIR=
PYTHON_INSTALL=false
PYTHON_MODE_INSTALL=
DOWNLOAD_PYTHON=
ERICSSON_NETWORK=
ERICSSON_PROXY=false
HTTPS_PROTOCOL=true

__init_setup_project_dev_5gcicd
# If no arguments are given, run as developer and last saved configuration
if [ $# -eq 0 ]; then
   __setup_project
else
   while [ $# -ge 1 ]
   do
      case $1 in
         # Show help
         -h|--help)
            __show_help_dev_5gcicd
            return 0
            ;;
         -i|--install)
            PYTHON_INSTALL=true
            shift
            ;;
         -d|--download)
            DOWNLOAD_PYTHON=--download
            shift
            ;;
         -ne|--no_ericsson)
             ERICSSON_NETWORK=--no_ericsson
             shift
             ;;
         -p|--proxy)
             ERICSSON_PROXY=true
             shift
             ;;
         -py|--python)
             shift
             if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || \
                [ "$1" = "-f" ] || [ "$1" = "--force" ] || \
                [ "$1" = "-i" ] || [ "$1" = "--install" ] || \
                [ "$1" = "-d" ] || [ "$1" = "--download" ] || \
                [ "$1" = "-ne" ] || [ "$1" = "--no_ericsson" ] || \
                [ "$1" = "-p" ] || [ "$1" = "--proxy" ] || \
                [ "$1" = "-o" ] || [ "$1" = "--offline" ] || \
                [ "$1" = "--http" ]
             then
                 PYTHON_MODE_INSTALL=development
             elif [ "$1" = "production" ] || [ "$1" = "development" ] || [ "$1" = "security" ]
             then
                 PYTHON_MODE_INSTALL=$1
                 shift
             else
                 __error "Error: The Installation Mode is not correct."
                 __show_help_dev_5gcicd
                 return 1
             fi
             export PYENV_ROOT="$(dirname ${DEV_5GCICD_ROOT})/pyenv_dev_5gcicd_${PYTHON_MODE_INSTALL}/"
             ;;
         -o|--offline)
             shift
             if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] || \
                [ "$1" = "-f" ] || [ "$1" = "--force" ] || \
                [ "$1" = "-i" ] || [ "$1" = "--install" ] || \
                [ "$1" = "-d" ] || [ "$1" = "--download" ] || \
                [ "$1" = "-ne" ] || [ "$1" = "--no_ericsson" ] || \
                [ "$1" = "-p" ] || [ "$1" = "--proxy" ] || \
                [ "$1" = "-py" ] || [ "$1" = "--python" ] || \
                [ "$1" = "--http" ]
             then
                 PYTHON_PACKAGES_DIR=/tsp/BBSC/portable-tools/python_repo/
             else
                 PYTHON_PACKAGES_DIR="$1"
                 shift
             fi
             if [ ! -d ${PYTHON_PACKAGES_DIR} ]
             then
                __error "Error: The directory does not exist."
                __show_help_dev_5gcicd
                return 1
             fi
             PYTHON_TYPE_INSTALLATION=offline
             ;;
         --http)
             HTTPS_PROTOCOL=false
             shift
             ;;
         *) # Catch faulty arguments
            __error "Error: faulty argument/s, try setup.sh -h for help"
            return 1
            ;;
      esac
   done
   __setup_project
fi

__info ""
__status "Done. Project setup finished"
__info "\tDEV_5GCICD_ROOT:          ${DEV_5GCICD_ROOT:-<empty>}"
__info "\tPYTHON MODE INSTALLATION: ${PYTHON_MODE_INSTALL:-<empty>}"
__info "\tPYTHON TYPE INSTALLATION: ${PYTHON_TYPE_INSTALLATION:-<empty>}"
__info "\tGIT aliases:              `git config --get-regexp '^alias\.' | sed 's/.*\.\([^ ]*\) .*/\1/' | tr '\n' ' '`"
__info ""

__clear_var_install_python_dev_5gcicd
unset __clear_var_install_python_dev_5gcicd

#!/usr/bin/env bash

# Install python and the python packages.
# Versions and what packages to install are in packages.yaml.
# Depending the type installation script will use the file that it is into
# "env/cfg/python/development/" (default) or "env/cfg/python/production/"

function __clear_var_functions_install_py()
{
   unset PYTHON_PACKAGES_DIR
   unset PYTHON_MODE_INSTALLATION
   unset PYTHON_PROJ_ROOT
   unset PYTHON_PYENV_ROOT
   unset USE_ERICSSON_NETWORK
   unset DOWNLOAD_PYTHON_DEP
   unset __print_error_py
   unset __print_py
   unset __git_identifier_py
   unset __get_version_py
   unset __setup_python_py
   unset __install_virtualenv_py
   unset __show_help_install_py
   unset __install_requirements_py
   unset __install_packages_py
}

function __print_error_py()
{
   # Parameter $1: Message to print.
   local message="$1"
   echo "------------------------------------------------------------------------------------------------------------------"
   echo "$(date) [$(basename ${BASH_SOURCE})] ERROR: ${message}"
   echo "------------------------------------------------------------------------------------------------------------------"
   return -1
}

function __print_py()
{
   # Parameter $1: Message to print.
   local message="$1"
   echo "$(date) [$(basename ${BASH_SOURCE})] INFO: ${message}"
}

###############################################################################
# Returns branch name, commit id in case of detached state, or tag identifier if commit id is associated to any; summing up:
# 1) in branch => returns branch name
# 2) in commit-id with tag associated => returns tag name
# 3) in commit-id with no tag associated => returns commit-id (short format)
###############################################################################
function __git_identifier_py()
{
   local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
   if [ "${branch}" == "HEAD" ]; then
      local last_commit=$(git log -n 1 --format=%h)
      local name_rev=$(git name-rev ${last_commit})
      echo "${name_rev}" | egrep "(.*)( +)tags/" >/dev/null
      if [ $? -eq 0 ]; then
         # Get the tag name, ignore only ^0, but not ^N nor ancestors
         branch=$(echo "${name_rev}" | cut -d/ -f2  | sed 's/\^0//')
      else
         # Last commit
         branch=${last_commit}
      fi
   fi
   [[ -z "${branch}" ]] && { branch="no_branch"; }
   echo ${branch}
}

function __get_version_py()
{
   # Parameter $1: The element to get the version.
   local package_name=$1
   # INPUT: File contents:
   #  ........
   #  ........
   #  python:
   #     version: 2.7.9
   #     package1: xx.y.z
   #     package2: a.bc
   #     package3: d.e.f
   #  ........
   #  ........
   #
   # OUTPUT: 13.1.2
   # This sentence does several actions:
   # 1) Delete all lines before "python:" word and after "package2" word.
   #    Result:
   #    python:
   #       version: 2.7.9
   #       package1: xx.y.z
   #       package2: a.bc
   # 2) The new string is filtered using the content of package2
   #    Result:
   #       package2:  a.bc
   # 3) Now, split the new string using ":" as separator, and get the 2nd value.
   #    Result:
   #      a.bc
   #  4) Format the value deleting the blanks, \n and single quotes.
   #    Result:  a.bc
   local package_version=$(sed -e '/^python:/,/${package_name}:/!d' ${PYTHON_PROJ_ROOT}/env/cfg/python/${PYTHON_MODE_INSTALLATION}/packages.yaml | grep ${package_name} | cut -d ":" -f2 | tr "\n" " " | tr -d "[[:space:]]" | tr -d "'")
   echo ${package_version}
}

###############################################################################
function __setup_python_py()
{
   __print_py "Executing __setup_python_py..."
   local rc=0
   local python_version=(`__get_version_py version`)
   local python_release=${PYTHON_PYENV_ROOT}/versions/${python_version}
   
   pushd $(pwd) >/dev/null
   __install_python_py ${python_version} ${python_release}
   rc=$?
   popd >/dev/null
   if [ ${rc} -eq 0 ]; then
      if [ ! -z "${PYTHON_PACKAGES_DIR}" ]; then
         local python_packages_repo="file://${PYTHON_PACKAGES_DIR}/simple/"
      else
         if [ "${USE_ERICSSON_NETWORK}" = "true" ]; then
            local python_packages_repo="https://arm.mo.sw.ericsson.se/artifactory/api/pypi/pypi-remote/simple/"
         else
            local python_packages_repo=""
         fi
      fi
      __print_py "PYTHON REPOSITORY: ${python_packages_repo}"
      __install_virtualenv_py $(dirname ${python_release}) ${python_version} ${python_packages_repo}
      __install_packages_py ${python_packages_repo}
      rc=$?
   fi
   return ${rc}
}

###############################################################################
function __install_python_py()
{
   # Parameter $1: The python version.
   # Parameter $2: The path where the python version will be installed.
   # Parameter $3: The directory of python environment where it will be installed.
   __print_py "Executing __install_python_py..."
   local python_version=$1
   local python_name_version=Python-$1
   local python_tarball=${python_name_version}.tgz
   local python_release=$2

   local python_archives=${PYTHON_PYENV_ROOT}/archives
   [[ ! -d ${python_archives} ]] &&  { mkdir -p ${python_archives}; }

   if [ ! -z "${PYTHON_PACKAGES_DIR}" ]; then
      local python_url=https://www.python.org/ftp/python/
      [[ -e ${PYTHON_PACKAGES_DIR}/${python_tarball} ]] && { cp ${PYTHON_PACKAGES_DIR}/${python_tarball} ${python_archives}/; }
   else
      if [ "${USE_ERICSSON_NETWORK}" = "true" ]; then
         local python_url=https://arm.mo.sw.ericsson.se/artifactory/simple/python.org-ftp-python/
      else
         local python_url=https://www.python.org/ftp/python/
      fi
   fi

   if [ ! -x ${python_release}/bin/python ]; then
      local python_log=${PYTHON_PYENV_ROOT}/logs/${python_name_version}_$(date +%s)
      mkdir -p $(dirname ${python_log})
      __print_py "Python install log file: ${python_log}"
      __print_py "Downloading ${python_tarball}..."

      if [ -e ${python_archives}/${python_tarball} ]
      then
         __print_py "Don't download the file ${python_tarball}. The file already exists..."
      else
         __print_py "PYTHON_URL: ${python_url}"
         \curl --fail --location --max-redirs 10 --max-time 1800 --connect-timeout 30 --retry-delay 2 --retry 3 -o ${python_archives}/${python_tarball} ${python_url}/${python_version}/${python_tarball} || __print_error_py "Error Downloading ${python_tarball}. Exiting..."
      fi

      __print_py "Extracting ${python_tarball}..."
      local python_sources=${PYTHON_PYENV_ROOT}/src
      mkdir -p ${python_sources}
      tar xzvf ${python_archives}/${python_tarball} -C ${python_sources} --no-same-owner >> ${python_log} 2>&1 || __print_error_py "Error Extracting ${python_tarball}. Exiting..."

      cd ${python_sources}/${python_name_version}

      __print_py "Configuring ${python_name_version}..."
      ./configure --prefix=${python_release} --libdir=${python_release}/lib >> ${python_log} 2>&1 || __print_error_py "Error Configuring ${python_name_version}. Exiting..."

      __print_py "Compiling ${python_name_version}..."
      make -j$(grep ^processor /proc/cpuinfo | wc -l) >> ${python_log} 2>&1 || __print_error_py "Error Compiling ${python_name_version}. Exiting..."

      __print_py "Installing ${python_name_version}..."
      make install >> ${python_log} 2>&1 || __print_error_py "Error Installing ${python_name_version}. Exiting..."

      # Install setuptools and pip
      __print_py "Bootstrapping pip installer..."
      ${python_release}/bin/python -m ensurepip >> ${python_log} 2>&1
   else
      __print_py "${python_name_version} is already installed!"
   fi

   # If the symbolic lynk to python does not exist, it will be added.
   local python_bin=$(dirname ${python_release})/bin
   if [ "$(readlink ${python_bin})" != "${python_release}/bin" ]; then
      ln -sf ${python_release}/bin ${python_bin}
   fi
   # This sentences checks if the python path is in PATH variable. If it is not in variable, python path will be added.
   if ! echo ${PATH} | egrep -q "(^|:)${python_bin}($|:)"; then
      export PATH=${python_bin}:${PATH}
   fi

   return 0
}

###############################################################################
function __install_virtualenv_py()
{
   # Parameter $1: The path where the virtualenv will be installed.
   # Parameter $2: The python version.
   # Parameter $3: The repository where the python packages are stored.
   __print_py "Executing __install_virtualenv_py..."
   local virtualenv_release=$1/py_$(__git_identifier_py | sed -e 's:/:_:g')
   local python_version=$2
   local python_packages_repo=$3
   local install_python_packages_repo=""
   [[ ! -z "${python_packages_repo}" ]] && { install_python_packages_repo="-i ${python_packages_repo}"; }

   # Install virtual environment if it has not been already installed and activate it
   if [[ ! -d ${virtualenv_release} || "$(cat ${virtualenv_release}/.py_version)" != "${python_version}" ]]; then
      local virtualenv_version=(`__get_version_py virtualenv`)
      __print_py "Installing [virtualenv==${virtualenv_version}]..."
      pip install virtualenv==${virtualenv_version} ${install_python_packages_repo} || __print_error_py "Error Installing virtualenv ${virtualenv_version}. Exiting..."

      __print_py "Creating $(basename ${virtualenv_release}) virtual environment..."
      [ -d ${virtualenv_release} ] && rm -rf ${virtualenv_release}
      virtualenv ${virtualenv_release} 2>&1 || __print_error_py "Error Creating $(basename ${virtualenv_release}) virtual environment. Exiting..."
      echo ${python_version} > ${virtualenv_release}/.py_version
   fi
   __print_py "Activating $(basename ${virtualenv_release}) virtual environment..."
   . ${virtualenv_release}/bin/activate 2>&1 || __print_error_py "Error Activating $(basename ${virtualenv_release}) virtual environment. Exiting..."

   # Upgrade pip (neccesary to install the requirements)
   local pip_version=(`__get_version_py pip_installer`)
   __print_py "Upgrading [pip==${pip_version}]..."
   __install_requirements_py pip==${pip_version} ${python_packages_repo} || __print_error_py "Error Upgrading pip ${pip_version}. Exiting..."
   return 0
}

function __install_requirements_py()
{
   # Parameter $1: The repository where the python packages are stored.
   # Parameter $2: The list of requirements that will be installed.
   __print_py "Executing __install_requirements_py..."
   local list_requirements_python=$1
   local python_packages_repo=$2
   local install_python_packages_repo=""
   [[ ! -z "${python_packages_repo}" ]] && { install_python_packages_repo="-i ${python_packages_repo}"; }
   local python_archives=${PYTHON_PYENV_ROOT}/archives

   if [ -z "${PYTHON_PACKAGES_DIR}" ] && [ ${DOWNLOAD_PYTHON_DEP} == true ]; then
      __print_py "Downloading the requirements ${list_requirements_python} ${install_python_packages_repo}..."
      pip download --exists-action i ${list_requirements_python} --dest ${python_archives} ${install_python_packages_repo}
      dir2pi --normalize-package-names ${python_archives}
   fi

   # Install the required packages
   __print_py "Installing [${list_requirements_python}]..."
   pip --no-cache-dir install ${list_requirements_python} ${install_python_packages_repo} || __print_error_py "Error Installing ${list_requirements_python}. Exiting..."
   return 0
}

###############################################################################
function __install_packages_py()
{
   # Parameter $1: The repository where the python packages are stored.
   __print_py "Executing __install_packages_py..."
   local python_packages_repo=$1
   # Install PyYAML (neccesary to get the requirements)
   local PyYAML_version=(`__get_version_py PyYAML`)
   __print_py "Installing [PyYAML==${PyYAML_version}]..."
   __install_requirements_py PyYAML==${PyYAML_version} ${python_packages_repo} || __print_error_py "Error Installing PyYAML ${PyYAML_version}. Exiting..."

   # Install pip2pi (neccesary to get the requirements_python)
   local pip2pi_version=(`__get_version_py pip2pi`)
   __print_py "Installing [pip2pi==${pip2pi_version}]..."
   __install_requirements_py pip2pi==${pip2pi_version} ${python_packages_repo} || __print_error_py "Error Installing pip2pi ${pip2pi_version}. Exiting..."

   for requirements_type in requirements_pre requirements requirements_post
   do
      local requirements_python=$(${PYTHON_PROJ_ROOT}/env/python/build_settings.py python.${requirements_type} ${PYTHON_MODE_INSTALLATION} | tr '\n' ' ' | sed -e 's/ *$//')
      __print_py "${requirements_type} [${requirements_python}]"
      if [ ! -z "${requirements_python}" ]; then
         __install_requirements_py "${requirements_python}" ${python_packages_repo} || __print_error_py "Error Installing ${requirements_python}. Exiting..."
      fi
   done
   return 0
}

function __show_help_install_py()
{
   cat <<EOF
Setting Up the installation of python dependencies.
This file must be sourced into a bash shell, not executed.
Usage: source ${BASH_SOURCE[0]} [OPTION1 OPTION2 ...]

-h,  --help                      Display this help and exit.
-o,  --offline  <PACKAGE DIR>    The installation is done offline and this is the python package directory (absolute path).
                                 Default Installation: <online>.
-d,  --download                  Download python and the packages dependences.
-p,  --packages [PACKAGES TYPE]  The packages to install. Default value is development.
                                 Packages Type: <development/production/security>
-py, --pyenv   <PYENV DIR>       The python environment is installed into this directory (absolute path).
-ne, --no_ericsson               Install packages without using ericsson network.

EOF
}

#############
# EXECUTION #
#############

## Check own shell execution (preffixed with dot or source)
#[[ x"${BASH_SOURCE[0]}" = x"$0" ]] && { __print_error_py "This script must be executed 'sourced' !"; exit 1; }

# If no arguments are given, run as developer and last saved configuration
echo "setup_install_python-PYTHON ENVIRONMENT"
PYTHON_MODE_INSTALLATION=development
USE_ERICSSON_NETWORK=true
PYTHON_PACKAGES_DIR=
PYTHON_PROJ_ROOT="`pwd`"
PYTHON_PYENV_ROOT=`dirname ${PYTHON_PROJ_ROOT}`
DOWNLOAD_PYTHON_DEP=false

if [ $# -eq 0 ]; then
   __setup_python_py
else
   while [ $# -ge 1 ]
   do
       case $1 in
          # Show help
          -h|--help)
             __show_help_install_py
             return 0
             ;;
          -d|--download)
             DOWNLOAD_PYTHON_DEP=true
             shift
             ;;
          -ne|--no_ericsson)
             USE_ERICSSON_NETWORK=false
             shift
             ;;
          -p|--packages)
             shift
             if [ -z "$1" ] || [ "$1" = "-r" ] || [ "$1" = "--repo" ] || \
                [ "$1" = "-py" ] || [ "$1" = "--pyenv" ] || \
                [ "$1" = "-o" ] || [ "$1" = "--offline" ] || \
                [ "$1" = "-d" ] || [ "$1" = "--download" ] || \
                [ "$1" = "-ne" ] || [ "$1" = "--no_ericsson" ] || \
                [ "$1" = "-h" ] || [ "$1" = "--help" ]
             then
                PYTHON_MODE_INSTALLATION=development
             elif [ "$1" = "production" ] || [ "$1" = "development" ] || [ "$1" = "security" ]
             then
                 PYTHON_MODE_INSTALLATION=$1
                 shift
             else
                 echo "Error: The Packages Type is not correct."
                 return 1
             fi
             ;;
          -o|--offline)
             shift
             __print_py "Package Directory -$1-"
             if [ -z "$1" ] || [ "$1" = "-r" ] || [ "$1" = "--repo" ] || \
                [ "$1" = "-py" ] || [ "$1" = "--pyenv" ] || \
                [ "$1" = "-p" ] || [ "$1" = "--packages" ] || \
                [ "$1" = "-d" ] || [ "$1" = "--download" ] || \
                [ "$1" = "-ne" ] || [ "$1" = "--no_ericsson" ] || \
                [ "$1" = "-h" ] || [ "$1" = "--help" ]
             then
                 __print_error_py "Missing the directory."
                 __show_help_install_py
                 return 1
             fi
             if [ ! -d $1 ]
             then
                __print_error_py "The directory does not exist."
                __clear_var_functions_install_py
                unset __clear_var_functions_install_py
                return 1
             fi
             PYTHON_PACKAGES_DIR=$1
             shift
             ;;
          -py|--pyenv)
             shift
             __print_py "Python Environment Directory -$1-"
             if [ -z "$1" ] || [ "$1" = "-o" ] || [ "$1" = "--offline" ] || \
                [ "$1" = "-o" ] || [ "$1" = "--offline" ] || \
                [ "$1" = "-p" ] || [ "$1" = "--packages" ] || \
                [ "$1" = "-d" ] || [ "$1" = "--download" ] || \
                [ "$1" = "-ne" ] || [ "$1" = "--no_ericsson" ] || \
                [ "$1" = "-h" ] || [ "$1" = "--help" ]
             then
                 __print_error_py "Missing the repository."
                 __clear_var_functions_install_py
                 unset __clear_var_functions_install_py
                 __show_help_install_py
                 return 1
             fi
             PYTHON_PYENV_ROOT=$1
             shift
             ;;
          # Catch faulty arguments
          *)
             __print_py "Error: faulty argument/s, try $0 -h for help"
             __clear_var_functions_install_py
             unset __clear_var_functions_install_py
             return 1
             ;;
       esac
   done
   __print_py "PYTHON_MODE_INSTALL: ${PYTHON_MODE_INSTALL}"
   __print_py "PYENV_ROOT: ${PYENV_ROOT}"
   __print_py "USE_ERICSSON_NETWORK: ${USE_ERICSSON_NETWORK}"
   __print_py "DOWNLOAD_PYTHON:  ${DOWNLOAD_PYTHON}"
   __setup_python_py
fi

__print_py "Install Python and Dependences finished"
__clear_var_functions_install_py
unset __clear_var_functions_install_py


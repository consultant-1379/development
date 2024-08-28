#!/bin/bash

function __print_tests()
{
   # Parameter $1: Message to print.
   local message="$1"
   echo "$(date) [$(basename ${BASH_SOURCE})] INFO: ${message}" >> ${LOG_CRON_FILE}
}

function __print_error_tests()
{
   # Parameter $1: Message to print.
   local message="$1"
   echo "------------------------------------------------------------------------------------------------------------------" >> ${LOG_CRON_FILE}
   echo "$(date) [$(basename ${BASH_SOURCE})] ERROR: ${message}" >> ${LOG_CRON_FILE}
   echo "------------------------------------------------------------------------------------------------------------------" >> ${LOG_CRON_FILE}
   return 1
}

function __delete_jenkins_objects_kubernetes()
{
   local namespace=$1
   local pod_name=${2:-""}
   helm delete 5gcicd-nightly-trigger --purge &>> ${LOG_CRON_FILE} 2>&1
   all_slave_jenkins=$(kubectl get pods -n ${namespace} | grep default |  awk '{ print $1 }')
   for slave_jenkins in ${all_slave_jenkins}
   do
      kubectl delete pods ${slave_jenkins} -n ${namespace} --force --grace-period=0 &>> ${LOG_CRON_FILE} 2>&1
   done
   [[ ! -z "${pod_name}" ]] && { kubectl delete pods ${pod_name} -n ${namespace} --force --grace-period=0 &>> ${LOG_CRON_FILE} 2>&1; }
}

function __get_pod_name()
{
   # Parameter $1: The agent to get its ip address.
   local name_object=$1
   local namespace=$2
   local status=${3:-Running}
   local name_pod=$(kubectl get pods -n ${namespace} | grep ${name_object} | grep -i ${status} | awk '{ print $1 }')
   echo ${name_pod}
}

function __wait_status_object_kubernetes
{
   local objtype=$1
   local objname=$2
   local namespace=$3
   local expected_status=${4:-Running}
   local max_sleep=${5:--1}
   local rc=0
   while :
   do
      local now_status=$(kubectl get ${objtype} -n ${namespace} | grep ${objname} | awk '{print $3}')
      __print_tests "Checking the ${objname}. Now status [${now_status}]. Expected status [${expected_status}]"
      if [ "${now_status}" = "${expected_status}" ]
      then
         rc=0
         break
      elif [[ "${now_status}" == *Error* ]] || [[ "${now_status}" == *ErrImagePull* ]] || \
           [[ "${now_status}" == *CrashLoopBackOff* ]] || [[ "${now_status}" == *rpc* ]] || \
           [[ "${now_status}" == *ImagePullBackOff* ]] || [[ "${now_status}" == *Killed* ]]
      then
         rc=1
         break
      fi
      sleep 4
      [[ ${max_sleep} -le -1 ]] && { continue; }
      max_sleep=$((max_sleep-1))
      [[ ${max_sleep} -le -1 ]] && { rc=1; break; }
   done
   __print_tests "RC ${rc}. ${objtype} ${objname} STATUS [${now_status}] EXPECTED [${expected_status}]"
   return ${rc}
}

function __wait_tokenUserFiles_exist_kubernetes
{
   local podname=$1
   local namespace=$2
   local max_sleep=${3:--1}
   local rc=0
   while :
   do
      local exist_file=$(kubectl exec -n ${namespace} ${podname} -- ls /home/jenkins/ | grep tokenUserFile)
      __print_tests "Checking NAMESPACE ${namespace} POD ${podname} in the file /home/jenkins/tokenUserFile => [${exist_file}]. "
      if [ ! -z "${exist_file}" ]
      then
         rc=0
         break
      fi
      sleep 1
      [[ ${max_sleep} -le -1 ]] && { continue; }
      max_sleep=$((max_sleep-1))
      [[ ${max_sleep} -le -1 ]] && { rc=1; break; }
   done
   __print_tests "RC ${rc}. NAMESPACE ${namespace} POD ${podname}. The file /home/jenkins/tokenUserFile => [${exist_file}]"
   return ${rc}
}
rc=0
USER=${1:-esdccci}
KUBERNETES_PLATFORM=${2:-k8s-gate}

ini_date=$(date +"%Y%m%d_%H%M%S")
LOG_CRON_FILE=/var/5gcicd-development/testing_results/nightly_cron_${ini_date}.log

#Check if helm is configured correctly
helm init
/bin/date >> /tmp/date.log

#Clone repository in case it don't exist, other will delete and clone again?
mkdir -p /apps/repo/
[[ -d "/apps/repo/5gcicd-development" ]] && { rm -r -f /apps/repo/5gcicd-development; }
chmod 700 /root/.ssh/
chmod 600 /root/.ssh/..*
chmod 600 /root/.ssh/id_rsa
cp /apps/cfg/known_hosts /root/.ssh/known_hosts
chmod 644 /root/.ssh/known_hosts
git clone --recursive ssh://${USER}@gerrit.ericsson.se:29418/5gcicd/development /apps/repo/5gcicd-development &>> ${LOG_CRON_FILE} 2>&1
cd /apps/repo/5gcicd-development/
. ./setup.sh -py -k ${KUBERNETES_PLATFORM} &>> ${LOG_CRON_FILE} 2>&1

name_old_nightly_pod=$(__get_pod_name "5gcicd-nightly-trigger-jenkins" "5gcicd-nightly" "Running")
[[ ! -z "${name_old_nightly_pod}" ]] && { __delete_jenkins_objects_kubernetes "5gcicd-nightly" "${name_old_nightly_pod}"; }

#Install Jenkins on corresponding namespace
helm install --replace --namespace 5gcicd-nightly --name 5gcicd-nightly-trigger --set Master.NodePort=30832 -f ${PWD}/testing/jenkins/helm-jenkins-values.yaml ${PWD}/jenkins_module/deployments/jenkins/charts &>> ${LOG_CRON_FILE} 2>&1
__wait_status_object_kubernetes "pods" "5gcicd-nightly-trigger-jenkins" "5gcicd-nightly" "Running"
rc=$?
if [ ${rc} -ne 0 ]; then
   __delete_jenkins_objects_kubernetes "5gcicd-nightly"
   exit 1
fi
name_nightly_pod=$(__get_pod_name "5gcicd-nightly-trigger-jenkins" "5gcicd-nightly" "Running")
LOG_JENKINS_MASTER_FILE=/var/5gcicd-development/testing_results/${name_nightly_pod}_${ini_date}.log
kubectl logs -n 5gcicd-nightly ${name_nightly_pod} -f &>> ${LOG_JENKINS_MASTER_FILE} 2>&1 &
__wait_tokenUserFiles_exist_kubernetes ${name_nightly_pod} "5gcicd-nightly"
rc=$?
if [ ${rc} -ne 0 ]; then
   __delete_jenkins_objects_kubernetes "5gcicd-nightly" ${name_nightly_pod}
   exit 1
fi

export JENKINS_NODE_PORT=$(kubectl get --namespace 5gcicd-nightly -o jsonpath="{.spec.ports[0].nodePort}" services 5gcicd-nightly-trigger-jenkins)
export JENKINS_NODE_IP=$(kubectl describe pods --namespace 5gcicd-nightly ${name_nightly_pod} | grep "Node:" | cut -f 2 -d '/' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
export JENKINS_URL=${JENKINS_NODE_IP}:${JENKINS_NODE_PORT}
export JENKINS_USER="admin"
export JENKINS_USER_PASS="admin"
export JENKINS_USER_TOKEN=$(kubectl exec -n 5gcicd-nightly ${name_nightly_pod} -- cat /home/jenkins/tokenUserFile)
${PWD}/code/jenkins_check/check_jenkins_jobs.py "sd-seed-job" &>> ${LOG_CRON_FILE} 2>&1

end_date=$(date +"%Y%m%d_%H%M%S")
mkdir -p /var/5gcicd-development/testing_results/${end_date}
all_jobs=$(kubectl exec -it -n 5gcicd-nightly ${name_nightly_pod} -- ls /var/jenkins_home/jobs/ | grep -v "ls:" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
for job in ${all_jobs}
do
   kubectl exec -it -n 5gcicd-nightly ${name_nightly_pod} -- tar -zcvf /var/jenkins_home/jobs/${job}_${end_date}.tar.gz /var/jenkins_home/jobs/${job}
   kubectl cp 5gcicd-nightly/${name_nightly_pod}:/var/jenkins_home/jobs/${job}_${end_date}.tar.gz /var/5gcicd-development/testing_results/${end_date}/${job}_${end_date}.tar.gz
   kubectl exec -it -n 5gcicd-nightly ${name_nightly_pod} -- rm -f /var/jenkins_home/jobs/${job}_${end_date}.tar.gz
done

__delete_jenkins_objects_kubernetes "5gcicd-nightly" ${name_nightly_pod}

mv ${LOG_CRON_FILE} /var/5gcicd-development/testing_results/${end_date}/nightly_cron_${ini_date}_${end_date}.log
mv ${LOG_JENKINS_MASTER_FILE} /var/5gcicd/testing_results/${end_date}/${name_nightly_pod}_${ini_date}_${end_date}.log
exit 0

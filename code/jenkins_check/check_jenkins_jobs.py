#!/usr/bin/env python

import sys
import argparse
import logging
import jenkins

from libcommon.cicd5g_logger import CiCd5gLogger
import libcommon.constants as constants
from libcommon.utils import Timestamp

# CiCd5gLogger.config_cicd_logger()
# logger = logging.getLogger(__name__)

jenkins_server = jenkins.Jenkins("http://%s" % (constants.JENKINS_URL), username=constants.JENKINS_USER,
                         password=constants.JENKINS_USER_TOKEN)
print("constants.JENKINS_URL " + str(constants.JENKINS_URL))
print("constants.JENKINS_USER " + str(constants.JENKINS_USER))
print("constants.JENKINS_USER_TOKEN " + str(constants.JENKINS_USER_TOKEN))

def parse_args_check_jenkins():
    """ Parse arguments from main method """
    parser = argparse.ArgumentParser()
    parser.add_argument("jenkins_ci_job", help="The name os jenkins pod ", default="sd-seed-job")
    parser.add_argument("jenkins_dev_jobs", help="The namespace of jenkins deploy ", default=[], nargs='*')
    arguments = parser.parse_args()
    return arguments

def jenkins_jobs_to_ckeck(jobs, ci_job, dev_jobs):
    check_jenkins_jobs=list()
    for job in jobs:
        print("job: %s\n" % job)
        addJob = True
        if job["name"] == ci_job:
            addJob = False
        for dev_job in dev_jobs:
            if job["name"] == dev_job:
                addJob = False
                break
        if addJob:
            check_jenkins_jobs.append(job)
    return check_jenkins_jobs

def init_result_jobs_to_ckeck(jobs):
    result_jobs = dict()
    for new_job in jobs:
        job_data = dict()
        job_data["build"] = 0
        job_data["status"] = "EMPTY"
        job_data["executed"] = False
        result_jobs[new_job["name"]] = job_data
    return result_jobs

def run_check_jenkins_seed_job(jenkins_seed_job):
    successJob = False
    exitLoop = False
    try:
        print("---------------------------------------------------------------------------------------------------")
        print("---------------------------------------------------------------------------------------------------")
        print("Checking if %s exist..." % (jenkins_seed_job))
        print("---------------------------------------------------------------------------------------------------")
        jenkins_server.assert_job_exists(jenkins_seed_job)
        print("---------------------------------------------------------------------------------------------------")
        print("%s exist!!!" % (jenkins_seed_job))
        print("---------------------------------------------------------------------------------------------------")
    except jenkins.JenkinsException:
        return successJob
    while not exitLoop:
        print("---------------------------------------------------------------------------------------------------")
        print("---------------------------------------------------------------------------------------------------")
        print("new_job Name                       : %s" % (jenkins_seed_job))
        print("---------------------------------------------------------------------------------------------------")
        successful_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_SUCCESSFUL_BUILD]
        completed_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_COMPLETED_BUILD]
        unsuccessful_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_UNSUCCESSFUL_BUILD]
        failed_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_FAILED_BUILD]
        unstable_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_UNSTABLE_BUILD]
        last_build = jenkins_server.get_job_info(jenkins_seed_job)[constants.LAST_BUILD]
        print("new_job last Successful Execution  : %s" % (successful_build))
        print("new_job last Completed Execution   : %s" % (completed_build))
        print("new_job last Unsuccessful Execution: %s" % (unsuccessful_build))
        print("new_job last Failed Execution      : %s" % (failed_build))
        print("new_job last Unstable Execution    : %s" % (unstable_build))
        print("new_job last Execution             : %s" % (last_build))
        print("---------------------------------------------------------------------------------------------------")
        print("---------------------------------------------------------------------------------------------------\n")
        if last_build:
            if completed_build is None or (last_build["number"] > completed_build["number"]):
                exitLoop = False
            elif (last_build["number"] == completed_build["number"]):
                if successful_build and (last_build["number"] == successful_build["number"]):
                    exitLoop = True
                    successJob = True
                elif failed_build and (last_build["number"] == failed_build["number"]):
                    exitLoop = True
                elif unstable_build and (last_build["number"] == unstable_build["number"]):
                    exitLoop = True
                elif unsuccessful_build and (last_build["number"] == unsuccessful_build["number"]):
                    exitLoop = True
                else:
                    exitLoop = True
            else:
                raise jenkins.JenkinsException('job [%s] last Execution < last Completed Execution' % jenkins_seed_job)
        else:
            exitLoop = False
        Timestamp.sleeping(1)
    return successJob


def run_check_jenkins_jobs(check_jenkins_jobs):
    """
    """
    exitLoop = False
    result_jobs = init_result_jobs_to_ckeck(jobs=check_jenkins_jobs)
    while not exitLoop:
        exitLoop = True
        for new_job in check_jenkins_jobs:
            print("---------------------------------------------------------------------------------------------------")
            print("---------------------------------------------------------------------------------------------------")
            print("new_job Name                       : %s" % (new_job["name"]))
            print("---------------------------------------------------------------------------------------------------")
            exitLoop = exitLoop and result_jobs[new_job["name"]]["executed"]
            if result_jobs[new_job["name"]]["executed"]:
                print("This last build was %d. This last result was %s"
                      % (result_jobs[new_job["name"]]["build"], result_jobs[new_job["name"]]["status"]))
                print("---------------------------------------------------------------------------------------------------")
                print("---------------------------------------------------------------------------------------------------\n")
                continue
            successful_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_SUCCESSFUL_BUILD]
            completed_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_COMPLETED_BUILD]
            unsuccessful_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_UNSUCCESSFUL_BUILD]
            failed_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_FAILED_BUILD]
            unstable_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_UNSTABLE_BUILD]
            last_build = jenkins_server.get_job_info(new_job["name"])[constants.LAST_BUILD]

            print("new_job last Successful Execution  : %s" % (successful_build))
            print("new_job last Completed Execution   : %s" % (completed_build))
            print("new_job last Unsuccessful Execution: %s" % (unsuccessful_build))
            print("new_job last Failed Execution      : %s" % (failed_build))
            print("new_job last Unstable Execution    : %s" % (unstable_build))
            print("new_job last Execution             : %s" % (last_build))
            print("---------------------------------------------------------------------------------------------------")
            print("---------------------------------------------------------------------------------------------------\n")
            if last_build:
                if completed_build is None or (last_build["number"] > completed_build["number"]):
                    result_jobs[new_job["name"]]["build"] = last_build["number"]
                    result_jobs[new_job["name"]]["status"] = "EXECUTING"
                    result_jobs[new_job["name"]]["executed"] = False
                elif (last_build["number"] == completed_build["number"]):
                    if successful_build and (last_build["number"] == successful_build["number"]):
                        result_jobs[new_job["name"]]["build"] = last_build["number"]
                        result_jobs[new_job["name"]]["status"] = "SUCCESSFUL"
                        result_jobs[new_job["name"]]["executed"] = True
                    elif failed_build and (last_build["number"] == failed_build["number"]):
                        result_jobs[new_job["name"]]["build"] = last_build["number"]
                        result_jobs[new_job["name"]]["status"] = "FAILED"
                        result_jobs[new_job["name"]]["executed"] = True
                        exitLoop = True
                        break
                    elif unstable_build and (last_build["number"] == unstable_build["number"]):
                        result_jobs[new_job["name"]]["build"] = last_build["number"]
                        result_jobs[new_job["name"]]["status"] = "UNSTABLE"
                        result_jobs[new_job["name"]]["executed"] = True
                    elif unsuccessful_build and (last_build["number"] == unsuccessful_build["number"]):
                        result_jobs[new_job["name"]]["build"] =  last_build["number"]
                        result_jobs[new_job["name"]]["status"] = "UNSUCCESSFUL"
                        result_jobs[new_job["name"]]["executed"] = True
                    else:
                        result_jobs[new_job["name"]]["build"] = last_build["number"]
                        result_jobs[new_job["name"]]["status"] = "ABORT"
                        result_jobs[new_job["name"]]["executed"] = True
                        exitLoop = True
                        break
                else:
                    raise jenkins.JenkinsException(
                        'job [%s] last Execution < last Completed Execution' % new_job["name"])
            else:
                result_jobs[new_job["name"]]["build"] = 0
                result_jobs[new_job["name"]]["status"] = "EMPTY"
                result_jobs[new_job["name"]]["executed"] = False
            Timestamp.sleeping(1)
        print("result_jobs " + str(result_jobs))
        print("exitLoop %s" % (exitLoop))
    return 0

if __name__ == "__main__":
    result = 0
    try:
        ARGS = parse_args_check_jenkins()
        JENKINS_CI_JOB = ARGS.jenkins_ci_job
        JENKINS_DEV_JOBS = ARGS.jenkins_dev_jobs
        print("JENKINS_CI_JOB      [" + JENKINS_CI_JOB + "]")
        print("JENKINS_DEV_JOBS    [" + str(JENKINS_DEV_JOBS) + "]")
        isOk = run_check_jenkins_seed_job(jenkins_seed_job=JENKINS_CI_JOB)
        if not isOk:
            result = -1
        if result == 0:
            isOk = True
            for dev_job in JENKINS_DEV_JOBS:
                isOk = run_check_jenkins_seed_job(jenkins_seed_job=dev_job)
                if not isOk:
                    result = -2
                    break
            if result == 0:
                all_jenkins_jobs = jenkins_server.get_all_jobs()
                check_jenkins_jobs = jenkins_jobs_to_ckeck(jobs=all_jenkins_jobs,
                                                           ci_job=JENKINS_CI_JOB,
                                                           dev_jobs=JENKINS_DEV_JOBS)
                isOk = True
                if len(check_jenkins_jobs) > 0:
                    isOk = run_check_jenkins_jobs(check_jenkins_jobs=check_jenkins_jobs)
                else:
                    print("There are not jobs to monitor!!!")
                if not isOk:
                    result = -3
    except KeyboardInterrupt as kexcep:
        print("KeyboardInterrupt at checking jenkins. [%s] !!!" % (kexcep.message))
        result = 1
    except jenkins.JenkinsException as jexcep:
        print("JenkinsException at checking jenkins [%s] !!!" % (jexcep.message))
        result = -4
    except Exception as gexcep:
        print("GeneralException at checking jenkins [%s] !!!" % (gexcep.message))
        result = -5
    sys.exit(result)

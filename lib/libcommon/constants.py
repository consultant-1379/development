""" Definitions of constants """
import os
import time
import datetime

CICD5G_DIR = os.getenv("CICD5G_ROOT")
ENV_CICD5G = os.getenv("ENV_CICD5G")
os.environ.setdefault("TEST_DATE_CICD5G", str(datetime.datetime.fromtimestamp(time.time()).strftime('%Y%m%d_%H%M%S')))
TEST_DATE_CICD5G = os.getenv("TEST_DATE_CICD5G")
NAMESPACE_TESTS = os.getenv("NAMESPACE_TESTS")
NODE_IPADDRESS = os.getenv("NODE_IPADDRESS")
APCERA_DOMAIN = os.getenv("APCERA_DOMAIN")
OPERATING_SYSTEM_IMG=os.getenv("OPERATING_SYSTEM_IMG") or "rhel"

JENKINS_NODE_PORT = os.getenv("JENKINS_NODE_PORT")
JENKINS_NODE_IP = os.getenv("JENKINS_NODE_IP")
JENKINS_URL = os.getenv("JENKINS_URL")
JENKINS_USER = os.getenv("JENKINS_USER")
JENKINS_USER_PASS = os.getenv("JENKINS_USER_PASS")
JENKINS_USER_TOKEN = os.getenv("JENKINS_USER_TOKEN")

LAST_SUCCESSFUL_BUILD = "lastSuccessfulBuild"
LAST_COMPLETED_BUILD = "lastCompletedBuild"
LAST_UNSUCCESSFUL_BUILD = "lastUnsuccessfulBuild"
LAST_FAILED_BUILD = "lastFailedBuild"
LAST_UNSTABLE_BUILD = "lastUnstableBuild"
LAST_BUILD = "lastBuild"

def _get_path(folder):
    """
    Function that adapts the path of the input directory in development
    or keep it in production mode
    :param folder: the path to the directory
    :return: 'folder' in production or relative to $ENVIRONMENT_ROOT in development
    """
    path = folder
    if not os.path.exists(path):
        path_base_name = os.path.split(os.path.split(path)[0])[1]
        path = os.path.join(CICD5G_DIR, path_base_name + '/')
        if not os.path.exists(path):
            os.makedirs(path)
    return path

if CICD5G_DIR:
    if not os.path.exists(os.path.join(CICD5G_DIR, "testing_results")):
        os.makedirs(os.path.join(CICD5G_DIR, "testing_results"))
    PATH_TESTING_RESULTS = os.path.join(CICD5G_DIR, "testing_results", TEST_DATE_CICD5G)
    if not os.path.exists(PATH_TESTING_RESULTS):
        os.makedirs(PATH_TESTING_RESULTS)
    CICD5G_FT_DIR = os.path.join(CICD5G_DIR, "testing", "FT")
    CICD5G_ST_DIR = os.path.join(CICD5G_DIR, "testing", "ST")

if os.path.exists(os.path.join(CICD5G_DIR, "env", "cfg", "logging", "logging.conf")):
    LOGGING_CONFIG = os.path.join(CICD5G_DIR, "env", "cfg", "logging", "logging.conf")
else:
    LOGGING_CONFIG = os.path.join(os.path.dirname(__file__), "cfg", "logging.conf")

DOCKER_PLATFORM = "docker"
APCERA_PLATFORM = "apcera"
KUBERNETES_PLATFORM = "kubernetes"
PLATFORM_DEFAULT = DOCKER_PLATFORM
MAX_TIME_SLEEP = 30

OS_UBUNTU = "ubuntu"
OS_RHEL_ATOMIC = "rhel-atomic"

ARM_DOCKER_HTTP = os.getenv("ARM_DOCKER_HTTP_PROTOCOL") or "https"
ARM_DOCKER_USER = os.getenv("ARM_DOCKER_USER")
ARM_DOCKER_PASS = os.getenv("ARM_DOCKER_PASS")

KUBERNETES_STORAGE_CLASS_NAME = os.getenv("KUBERBETES_STORAGE_CLASS_NAME") or "erikube-nfs"
KUBERNETES_NODE = os.getenv("KUBERNETES_NODE") or None
KUBERNETES_NODE_IP = os.getenv("KUBERNETES_NODE_IP") or None

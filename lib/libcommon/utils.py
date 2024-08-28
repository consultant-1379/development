""" Utils module """
import os
import time
import datetime
import subprocess
import logging
import random
import string

import libcommon.constants as constants
from libcommon.cicd5g_logger import CiCd5gLogger

CiCd5gLogger.config_cicd_logger(config_file=constants.LOGGING_CONFIG)
logger = logging.getLogger(__name__)

class Timestamp(object):
    """ Class to manage a Timestamp """
    @staticmethod
    def current_timestamp_formatted():
        """
        Get the current timestamp in the format '%Y-%m-%d %H:%M:%S'
        :return: the current timestamp
        """
        return datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H:%M:%S')

    @staticmethod
    def current_timestamp_seconds():
        """
        Get the current timestamp in seconds
        :return: the current timestamp in seconds
        """
        return time.time()

    @staticmethod
    def sleeping(seconds=60):
        """
        Sleep X seconds
        """
        logger.debug("Sleeping " + str(seconds) + " seconds......")
        time.sleep(seconds)

def get_attribute_from_dict(data, key):
    """
    it obtains value associated to a key in a data dictionary
    :param data         a dictionary with the data
    :param key          a dictionary key
    :return value       a value associated to a key or None if the key
                        doesn't exist
    """
    try:
        value = data.get(key)
    except:
        value = None
    logger.debug("GET-Key: [" + str(key)+ "] Value: [" + str(value) + "]")
    return value

def set_attribute_to_dict(data, key, value=None):
    """
    it obtains value associated to a key in a data dictionary
    :param data         a dictionary to store the data.
    :param key          a dictionary key.
    :param value        the new value.
    :return data        a dictionary with the data stored.
    """
    logger.debug("SET-Key: [" + str(key) + "] Value: [" + str(value) + "]")
    if value is not None and value is not "":
        data[key] = value
    logger.debug("SET-Data: [" + str(data) + "]")
    return data

def run_command_check_output(command, shell=True):
    try:
        logger.debug("Command: [" + str(command) + "]")
        command_output = subprocess.check_output(command, shell=shell)
    except subprocess.CalledProcessError as excep:
        logger.debug("Error Message: [" + str(excep.message) + "]")
        logger.debug("Error Output:  [" + str(excep.output) + "]")
        logger.debug("Error Code:    [" + str(excep.returncode) + "]")
        command_output = None
    logger.debug("Command Output: [" + str(command_output) + "]")
    return command_output

def run_command_call(command, shell=True):
    logger.debug("Command: [" + str(command) + "]")
    outResult = subprocess.call(command, shell=shell)
    logger.debug("Result: " + str(outResult))
    return outResult

def run_command_check_call(command, shell=True):
    try:
        logger.debug("Command: [" + str(command) + "]")
        outResult = subprocess.check_call(command, shell=shell)
    except subprocess.CalledProcessError as excep:
        logger.debug("Error Message: [" + str(excep.message) + "]")
        logger.debug("Error Output:  [" + str(excep.output) + "]")
        logger.debug("Error Code:    [" + str(excep.returncode) + "]")
        outResult = excep.returncode
    logger.debug("Command Output: [" + str(outResult) + "]")
    return outResult

def is_proxy_enabled():
    http_proxy = os.getenv("http_proxy".upper())
    https_proxy = os.getenv("https_proxy".upper())
    if http_proxy:
        return True, http_proxy
    elif https_proxy:
        return True, https_proxy
    else:
        return False, None

def get_random_id(size=8):
    uid = ''.join(random.choice(string.ascii_lowercase + string.digits) for x in range(size))
    return uid

def change_directory_timestamps(directory):
    if not os.path.exists(directory): return
    logger.info("change_directory_timestamps(): Changing the timestamp of directory %s ..." % directory)
    current_time = Timestamp.current_timestamp_seconds()
    os.utime(directory, (current_time, current_time))
    logger.info("change_directory_timestamps(): Done!!!")
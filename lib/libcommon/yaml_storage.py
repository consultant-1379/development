""" YAML storage module """
import logging
import libcommon.constants as constants
from libcommon.cicd5g_logger import CiCd5gLogger
import os
import fcntl

import yaml

class YamlStorage(object):
    """ Class to manage data storage in a YAML format """
    def __init__(self, file_name, blockFile = False, config_file=constants.LOGGING_CONFIG):
        """
        Constructor for Storage class. This is the base class to store any data in a file
        in YAML format.
        :param file_name         file to save the data
        """
        self._file_name = file_name
        CiCd5gLogger.config_cicd_logger(config_file=config_file)
        self._logger = logging.getLogger(__name__)
        if not os.path.isfile(file_name):
            open(self._file_name, 'w+').close()
        self._blockFile = blockFile

    def write(self, data):
        """
        Method to save data in the file in YAML format
        :param data: dictionary that contains to data to save
        :return: True if the data is written otherwise False
        """
        with open(self._file_name, "w+") as file:
            if self._blockFile: fcntl.flock(file, fcntl.LOCK_EX)
            try:
                yaml.dump(data, file, default_flow_style=False)
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
            except yaml.YAMLError:
                self._logger.error("The data is not yaml format. Could not write data to file "
                                   "[" + str(self._file_name) + "]")
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
                return False
        return True

    def read(self):
        """
        Method to load the data from a file in YAML format into a dictionary
        :return: the data read from the file in a dictionary or None if something was wrong
        """
        with open(self._file_name, "r") as file:
            if self._blockFile: fcntl.flock(file, fcntl.LOCK_EX)
            try:
                data = yaml.safe_load(file)
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
            except yaml.YAMLError:
                self._logger.error("The data is not yaml format. Could not read data to file "
                                   "[" + str(self._file_name) + "]")
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
                return None
        return data

    @staticmethod
    def convert_to_yaml(data_string):
        """
        Convert the string provided has a valid yaml format
        :param data_string: a string to be converted
        :return: the data converted in a dictionary or None if something was wrong
        """
        try:
            data = yaml.safe_load(data_string)
        except ValueError:
            return None
        return data

    @staticmethod
    def convert_from_yaml(data):
        """
        Convert the string provided has a valid yaml format
        :param data: a dictionary to be converted
        :return: the data converted in a string or None if something was wrong
        """
        try:
            data_string = yaml.dump(data, default_flow_style=False, default_style='"')
        except ValueError:
            return None
        return data_string
""" JSON storage module """
import json
import logging

import libcommon.constants as constants
from libcommon.cicd5g_logger import CiCd5gLogger
import os
import fcntl

class JsonStorage(object):
    """ Class to manage data storage in JSON format. """
    def __init__(self, file_name, blockFile = False, config_file=constants.LOGGING_CONFIG):
        """
        Constructor for Storage class. This is the base class to store any data in a file
        in JSON format.
        :param file_name         file to save the data
        """
        self._file_name = file_name
        CiCd5gLogger.config_cicd_logger(config_file=config_file)
        self._logger = logging.getLogger(__name__)
        if not os.path.isfile(file_name):
            open(self._file_name, "w+").close()
        self._blockFile = blockFile

    def write(self, data):
        """
        Method to save data in the file in json format
        :param data: dictionary that contains to data to save
        :return: True if the data is written otherwise False
        """
        with open(self._file_name, "w+") as file:
            if self._blockFile: fcntl.flock(file, fcntl.LOCK_EX)
            try:
                json.dump(data, file, sort_keys=True, indent=2)
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
            except json. ValueError:
                self._logger.error("The data is not json format. Could not write data to file "
                                   "[" + str(self._file_name) + "]")
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
                return False
        return True

    def read(self):
        """
        Method to load the data from a file in json format into a dictionary
        :return: the data read from the file in a dictionary or None if something was wrong
        """
        with open(self._file_name, "r") as file:
            if self._blockFile: fcntl.flock(file, fcntl.LOCK_EX)
            try:
                data = json.load(file)
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
            except ValueError:
                self._logger.error("The data is not json format. Could not read data from file "
                                   "[" + str(self._file_name) + "]")
                if self._blockFile: fcntl.flock(file, fcntl.LOCK_UN)
                return None
        return data

    @staticmethod
    def convert_to_json(data_string):
        """
        Convert the string provided has a valid json format
        :param data_string: a string to be converted
        :return: the data converted in a dictionary or None if something was wrong
        """
        try:
            data = json.loads(data_string)
        except ValueError:
            return None
        return data

    @staticmethod
    def convert_from_json(data):
        """
        Convert the string provided has a valid json format
        :param data: a dictionary to be converted
        :return: the data converted in a string or None if something was wrong
        """
        try:
            data_string = json.dumps(data, sort_keys = True, indent = 2)
        except ValueError:
            return None
        return data_string
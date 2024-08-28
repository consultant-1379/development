# pylint: disable=too-few-public-methods
""" 5G CICD logger module """
import os
import logging
import logging.config

import libcommon.constants as constants

class CiCd5gLogger(object):
    """
    Class to manage the 5G CICD traces file.
    """

    @staticmethod
    def config_cicd_logger(config_file=None):
        """
        Method to set the log configuration
        """
        if config_file and os.path.exists(config_file):
            logging.config.fileConfig(config_file, disable_existing_loggers=False)
        else:
            logging.config.fileConfig(constants.LOGGING_CONFIG, disable_existing_loggers=False)
    
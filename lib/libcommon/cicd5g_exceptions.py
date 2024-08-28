"""Custom exceptions for 5G CICD"""


class CiCd5gException(Exception):
    """Generic class for EDM exceptions"""
    def __init__(self, message):
        """Initialize the exception
        :param message     A string with the exception text"""
        super(CiCd5gException, self).__init__()
        self.message = message

    def __str__(self):
        return repr(self.message)


class NotFoundException(CiCd5gException):
    """Exception to indicate that the Device Manager did not found the resource"""


class InternalErrorException(CiCd5gException):
    """Exception to indicate that Device Manager has failed
    when processing a request from Device Configuration Interface"""


class ForbiddenException(CiCd5gException):
    """Exception to indicate that Device Manager has failed
    when processing a forbidden request from Device Configuration Interface"""

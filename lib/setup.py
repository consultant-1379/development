#!/usr/bin/env python

from setuptools import setup

__name__ = 'CICD5G_Libs'
__version__ = '1.0.0'

setup(
    name = __name__,
    version=__version__,
    description='Python Distribution 5g CI&CD Common Components Libraries',
    author='Roberto Valseca Vian',
    author_email='roberto.valseca@blue-tc.com',
    url='https://www.python.org/sigs/distutils-sig/',
    packages = ["libcommon"],
    package_data= {
        "libcommon": [
            "cfg/logging.conf"
        ]},
)
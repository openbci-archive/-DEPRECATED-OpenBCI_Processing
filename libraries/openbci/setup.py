'''
Basic ``setup.py``, intended for::

    $ python setup.py develop

Incomplete, does not specify dependencies etc.

After: 
http://packages.python.org/distribute/setuptools.html#basic-use


Created on Oct 23, 2015

@author: Teon Brooks
'''
from distribute_setup import use_setuptools
use_setuptools()

from setuptools import setup, find_packages

setup(
    name = "openbci",
    version = "0.1dev",
    description = "Custom MNE Raw Class for OpenBCI data",
    author="Teon Brooks",
    author_email="teon.brooks@gmail.com",
    install_requires=["mne >= 0.9",
                      "numpy >= 1.8"],
    
    packages = find_packages(),
)

#!/usr/bin/env python3
# Author: Gilles S. Biagomba
# Program: sherlock.py
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specifically recon).\n
# License: GNU General Public License v3.0

# Importing libraries
from datetime import date
import sys
import os
import tempfile
import requests
import argparse
import dnspython
import requests
import retirejs

# 
import halberd
import harvesters
import google
import hackrecon
import dirbpy
import masscan
import sslscan
import golismero
import docker
import havester
import tld
import fuzzywuzzy
import dnspython


# Setting up variables
pth = os.getcwd()
today = date.strftime("%d/%m/%Y")
pwd = pth/today
os.mkdir(pwd)

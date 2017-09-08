# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT 
##   https://www.dennyzhang.com/wp-content/mit_license.txt
##
## File : disk_usage_report.py
## Author : Denny <contact@dennyzhang.com>
## Description :
## --
## Created : <2017-01-15>
## Updated: Time-stamp: <2017-09-07 21:36:07>
##-------------------------------------------------------------------
import os, sys, json
import requests
import subprocess

def quit_if_empty(string, err_msg):
    if string is None or string == '':
        print("Error: string is null or empty. %s" % (err_msg))
        sys.exit(-1)

################################################################################
'''
python ./disk_usage_report.py --server_role couchbase --server_list 192.168.1.2,192.168.1.3

# Sample output:
'''

if __name__ == '__main__':
    print("hello")
## File : disk_usage_report.py ends

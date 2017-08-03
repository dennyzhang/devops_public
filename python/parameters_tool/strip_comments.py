#!/usr/bin/python
## File : strip_comments.py
## Created : <2017-08-03>
## Updated: Time-stamp: <2017-08-03 18:12:22>
## Description :
##    For a block of string, remove useless stuff
##       1. Remove leading whitespace
##       2. Remove tailing whitespace
##       3. Remove any lines start with #
##
## Sample:
##    export server_list="# server ip
##             
##             ## APP
##             138.68.52.73:22
##             ## loadbalancer
##             #138.68.254.56:2711
##             #138.68.254.215:2712"
##    server_list=$(echo "$server_list" | python ./strip_comments.py)
##    server_list: "138.68.52.73:22"
##-------------------------------------------------------------------
import os, sys

def strip_comment(string):
    string_list = []
    for line in string.split("\n"):
        line = line.strip()
        if line.startswith("#") or line == "":
            continue
        string_list.append(line)
    return "\n".join(string_list)

if __name__ == '__main__':
    string = sys.stdin.read()
    print(strip_comment(string))
## File : strip_comments.py ends

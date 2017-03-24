# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : git_pull_codedir.py
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2017-03-24>
## Updated: Time-stamp: <2017-03-24 15:47:33>
##-------------------------------------------------------------------
import os, sys
import sys
import logging
# Notice: Need to run: pip install GitPython
import git

logger = logging.getLogger("git_pull_codedir")
formatter = logging.Formatter('%(name)-12s %(asctime)s %(levelname)-8s %(message)s', '%a, %d %b %Y %H:%M:%S',)
file_handler = logging.FileHandler("/var/log/git_pull_codedir.log")
file_handler.setFormatter(formatter)
stream_handler = logging.StreamHandler(sys.stderr)
logger.addHandler(file_handler)
logger.addHandler(stream_handler)
#logger.setLevel(logging.ERROR)

def git_pull(code_dir):
    log.info("Run git pull in %s" %(code_dir))
    if ! os.path.exists(code_dir):
        logger.error("Code directory(%s): doesn't exist" % (code_dir))
        sys.exit(1)
    os.chdir(working_dir)
    g = git.cmd.Git(git_dir)
    g.pull()

# Sample python perform_git_pull.py --code_dirs "/data/code_dir/repo1,/data/code_dir/repo2"
if __name__ == '__main__':
    # --log_file="/var/log/perform_git_pull.log"
    separator = ","
    for code_dir code_dirs.split(separator):
        git_pull(code_dir)    
## File : git_pull_codedir.py ends

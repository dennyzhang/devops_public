# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : git_create_tag.py
## Author : Denny <denny@dennyzhang.com>
## Description : Create monthly git tag for all repos in your projects
## Dependency:
##        pip install GitPython
## Sample:
##        python git_create_tag.py -tag_name "2017-08-01" --delete_tag_already_exists \
##               --git_list_file /tmp/git_list.txt"
##
##        Sample of git_list_file
##                   git@bitbucket.org:dennyzhang/devops.git
##                   git@bitbucket.org:dennyzhang/frontend.git
##                   git@bitbucket.org:dennyzhang/backend.git
## --
## Created : <2017-03-24>
## Updated: Time-stamp: <2017-05-20 00:12:12>
##-------------------------------------------------------------------
import os, sys
import sys
import logging
import argparse
# Notice: Need to run: pip install GitPython
import git

log_file = "/var/log/%s.log" % (os.path.basename(__file__).rstrip('\.py'))
logging.basicConfig(filename=log_file, level=logging.DEBUG, format='%(asctime)s %(message)s')
logging.getLogger().addHandler(logging.StreamHandler())

def git_pull(code_dir):
    logging.info("Run git pull in %s" %(code_dir))
    if os.path.exists(code_dir) is False:
        logging.error("Code directory(%s): doesn't exist" % (code_dir))
        sys.exit(1)
    os.chdir(code_dir)
    g = git.cmd.Git(code_dir)
    output = g.pull()
    return output

# Sample python git_pull_codedir.py --code_dirs "/data/code_dir/repo1,/data/code_dir/repo2"
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--code_dirs', required=True, \
                        help="Code directories to pull. If multiple, separated by comma", type=str)
    l = parser.parse_args()
    code_dirs = l.code_dirs

    separator = ","
    for code_dir in code_dirs.split(separator):
        git_output = git_pull(code_dir)
        if git_output == 'Already up-to-date.':
            has_changed = False
        else:
            has_changed = True
            logging.info("Code has changed in %s. Detail: %s" % (code_dir, git_output))

    if git_output is True:
        sys.exit(1)
    else:
        sys.exit(0)
## File : git_create_tag.py ends

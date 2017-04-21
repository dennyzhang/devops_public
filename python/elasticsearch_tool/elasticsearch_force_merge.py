# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
##
## File : elasticsearch_force_merge.py
## Author : 
## Description :
##    Run force merge for existing indices, which has many deleted documents
## Sample:
##   - Run force-merge for indices which has many deleted records
##        python ./elasticsearch_force_merge.py --min_deleted_count 1000 --min_deleted_ratio 0.1
##
##   - Run force-merge for indices with matched index name
##        python ./elasticsearch_force_merge.py --es_pattern_regexp "master-.*|staging-.*"
##
##   - Run force-merge for all indices
##        python ./elasticsearch_force_merge.py --min_deleted_count 0 --min_deleted_ratio 0
##
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-04-17 21:40:32>
##-------------------------------------------------------------------
import argparse
import requests
import sys
import socket
import json
import re

NAGIOS_OK_ERROR=0
NAGIOS_EXIT_ERROR=2

indices_before = ""
################################################################################
def setup_custom_logger(name):
    import logging
    formatter = logging.Formatter(fmt='%(asctime)s %(levelname)-8s %(message)s',
                                  datefmt='%Y-%m-%d %H:%M:%S')
    log_fname = "/var/log/%s.log" % (name)
    handler = logging.FileHandler(log_fname, mode='w')
    handler.setFormatter(formatter)
    screen_handler = logging.StreamHandler(stream=sys.stdout)
    screen_handler.setFormatter(formatter)
    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)
    logger.addHandler(handler)
    logger.addHandler(screen_handler)
    return logger

def get_all_index_summary(es_host, es_port):
    url = "http://%s:%s/_cat/indices?v" % (es_host, es_port)
    r = requests.get(url)
    if r.status_code != 200:
        logger.error("Fail to run REST API: %s" % (url))
        sys_exit(es_host, es_port)

    l = []
    for line in r.content.split("\n"):
        # remove the header, and skip closed ES indices
        if line == '' or " index " in line  or " close " in line:
            continue
        l.append(line)
    return "\n".join(l)

def print_index_setting(es_host, es_port, index_name):
    url = "http://%s:%s/%s/_stats?pretty" % (es_host, es_port, index_name)
    r = requests.get(url)
    if r.status_code != 200:
        logger.error("Fail to run REST API: %s" % (url))
        sys_exit(es_host, es_port)
    content_json = json.loads(r.content)
    logger.info("Index setting for %s.\n\tdocs:%s\n\tmerges:%s\n\tsegments:%s\n\n" % \
        (index_name,
         json.dumps(content_json["_all"]["primaries"]["docs"]),
         json.dumps(content_json["_all"]["primaries"]["merges"]),
         json.dumps(content_json["_all"]["primaries"]["segments"])))
################################################################################

def sys_exit(es_host, es_port, exit_code = NAGIOS_EXIT_ERROR):
    if exit_code != 0:
        logger.error("Unexpected error has happened. Current summary of ES indices.")

    if indices_before != "":
        logger.info("Indices summary before force-merge.\n%s" % (indices_before))
    indices_after = get_all_index_summary(es_host, es_port)
    logger.info("Indices summary after force-merge.\n%s" % (indices_after))
    sys.exit(exit_code)

def get_es_index_info(es_host, es_port, es_pattern_regexp, \
                      min_deleted_count, min_deleted_ratio):
    index_list = []
    url = "http://%s:%s/_cat/indices?v" % (es_host, es_port)
    # TODO: error handling, if curl requests fails
    r = requests.get(url)
    '''
Sample output:
root@test:/# curl 172.17.0.8:9200/_cat/indices?v
health status index                                          pri rep docs.count docs.deleted store.size pri.store.size
green  open   master-index-098f6bcd4621d373cade4e832627b4f6    1   0          1            0      8.1kb          8.1kb
green  open   master-index-13a1f8adbec032ed68f3d035449ef48d    1   0          1            0     10.6kb         10.6kb
...
...
'''
    if r.status_code != 200:
        logger.error("Fail to run REST API: %s" % (url))
        sys_exit(es_host, es_port)

    # TODO: use python library for ES
    for line in r.content.split("\n"):
        # remove the header, and skip closed ES indices
        if line == '' or " index " in line  or " close " in line:
            continue
        else:
            line = " ".join(line.split())
            l = line.split()
            index_name = l[2]

            # skip indices, if not in the matched pattern
            if es_pattern_regexp != "":
                m = re.search(es_pattern_regexp, index_name)
                if m is None:
                    continue

            total_doc_count = int(l[5])
            deleted_doc_count = int(l[6])
            if min_deleted_count != 0 and min_deleted_ratio != 0:
                if (deleted_doc_count < min_deleted_count):
                    continue
                if float(deleted_doc_count)/total_doc_count < min_deleted_ratio:
                    continue
            index_list.append([index_name, total_doc_count, deleted_doc_count])
    return index_list

def force_merge_index(es_host, es_port, index_name):
    print_index_setting(es_host, es_port, index_name)

    # TODO: Quit if something wrong; get time performance
    # force-merge is a sync call, and it might take a long time
    url = \
          "http://%s:%s/%s/_forcemerge?pretty&only_expunge_deletes=true" % \
          (es_host, es_port, index_name)
    r = requests.post(url)
    if r.status_code != 200:
        logger.error("Fail to run REST API: %s" % (url))
        sys_exit(es_host, es_port)
    logger.info("http response: %s" % (r.content))

    print_index_setting(es_host, es_port, index_name)

# Sample:
# python ./elasticsearch_force_merge.py --es_pattern_regexp "master-.*|staging-.*" \
#          --min_deleted_count 1000 \
#          --min_deleted_ratio 0.1
#
# python /tmp/elasticsearch_force_merge.py --min_deleted_count 0  --min_deleted_ratio 0

logger = setup_custom_logger('myapp')

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--es_host', required=False, \
                        help="server ip or hostname for elasticsearch instance. Default value is ip of eth0", type=str)
    parser.add_argument('--es_port', default='9200', required=False, \
                        help="server port for elasticsearch instance", type=str)
    parser.add_argument('--es_pattern_regexp', required=False, default='', \
                        help="ES index name pattern. Only ES indices with matched pattern will be examined", type=str)
    parser.add_argument('--min_deleted_count', default=1000, required=False, \
                        help='If indices do not have too many deleted docs, skip the force merge', type=int)
    parser.add_argument('--min_deleted_ratio', default=0.05, required=False, \
                        help='If the ratio of deleted/total doc count is too small, skip the force merge', type=float)
    l = parser.parse_args()

    es_host = l.es_host
    es_port = l.es_port
    es_pattern_regexp = l.es_pattern_regexp
    min_deleted_count = int(l.min_deleted_count)
    min_deleted_ratio = float(l.min_deleted_ratio)

    # get ip of eth0, if es_host is not given
    if es_host is None:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        es_host = s.getsockname()[0]

    indices_stats = get_all_index_summary(es_host, es_port)
    logger.info("Indices summary:\n%s" % (indices_stats))
    es_index_list = get_es_index_info(es_host, es_port, es_pattern_regexp, \
                                      min_deleted_count, min_deleted_ratio)
    if len(es_index_list) == 0:
        logger.info("OK: no indices need to run force-merge.")
    else:
        indices_before = get_all_index_summary(es_host, es_port)
        updated_index_list = []
        for es_index in es_index_list:
            index_name = es_index[0]
            logger.info("Run force-merge for %s" % (index_name))
            force_merge_index(es_host, es_port, index_name)
            updated_index_list.append(index_name)
        logger.info("OK: Run force-merge successfully on below indices: %s" % (','.join(updated_index_list)))

        sys_exit(es_host, es_port, 0)
## File : elasticsearch_force_merge.py ends

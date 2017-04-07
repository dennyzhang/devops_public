# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
##
## File : elasticsearch_force_merge.py
## Author : 
## Description :
##    Run force merge for existing indices, when ratio of deleted count/doc count is over 0.1
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-04-07 10:29:02>
##-------------------------------------------------------------------
import argparse
import requests
import sys
import socket

def get_es_index_info(es_host, es_port, es_pattern_regexp, \
                      min_deleted_count, min_deleted_ratio):
    index_list = []
    url = "http://%s:%s/_cat/indices?v" % (es_host, es_port)
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
    # TODO: use python library for ES
    # TODO: error handling, if curl requests fails
    for line in r.content.split("\n"):
        # remove the header, and skip closed ES indices
        if line == '' or " index " in line  or " close " in line:
            continue
        else:
            line = " ".join(line.split())
            l = line.split()
            index_name = l[2]
            total_doc_count = int(l[5])
            deleted_doc_count = int(l[6])
            if deleted_doc_count < min_deleted_count || \
               float(deleted_doc_count)/total_doc_count < min_deleted_ratio:
                continue
            index_list.append([index_name, total_doc_count, deleted_doc_count])
    return index_list

def force_merge_index(es_host, es_port, index_name):
    # Get index setting, before merge

    # TODO: Quit if something wrong; get time performance
    # force-merge is a sync call, and it might take a long time
    url = "http://%s:%s/%s/_forcemerge?pretty&only_expunge_deletes=true" % \
                                                                    (es_host, es_port, index_name)
    r = requests.post(url)
    return True

# Sample:
# python ./elasticsearch_force_merge.py --es_pattern_regexp "master-.*|staging-.*" \
#          --min_deleted_count 1000 \
#          --min_deleted_ratio 0.1

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
    parser.add_argument('--min_deleted_ratio', default=0.1, required=False, \
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

    es_index_list = get_es_index_info(es_host, es_port, es_pattern_regexp, \
                                      min_deleted_count, min_deleted_ratio)

    # TODO: print timestamp
    updated_index_list = []
    for es_index in es_index_list:
        index_name = es_index[0]
        print "Run force-merge for %s" % (index_name)
        force_merge_index(es_host, es_port, index_name)
        updated_index_list.append(index_name)
    print "OK: Run force-merge successfully on below indices: %s" % (','.join(updated_index_list))
## File : elasticsearch_force_merge.py ends

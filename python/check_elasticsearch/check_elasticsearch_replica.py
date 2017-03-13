# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2017 DennyZhang.com
## Licensed under MIT
##   https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : check_elasticsearch_replica.py
## Author : Denny <denny@dennyzhang.com>
## Description :
##    Check all ES indices have more than $min_replica_count replicas
## --
## Created : <2017-02-24>
## Updated: Time-stamp: <2017-03-13 15:43:16>
##-------------------------------------------------------------------
import argparse
import requests

def get_es_index_list(es_host, es_port):
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
    # TODO: error handling, if curl requests fails
    for line in r.content.split("\n"):
        # remove the header
        if " index " in line or line == '':
            continue
        else:
            # get the column of index name
            line = ' '.join(line.split())
            l = line.split(" ")
            index_list.append(l[2])
    return index_list

def get_es_replica_count(es_host, es_port, index_name):
    number_of_replicas = -1
    url = "http://%s:%s/%s/_settings?pretty" % (es_host, es_port, index_name)
    r = requests.get(url)
    '''
Sample output:
        ...
        ...
        },
        "number_of_replicas" : "0",
        "uuid" : "31CQbyYKTT6UGtI3lbPfAg",
        "version" : {
          "created" : "2030399"        
        ...
        ...
    '''
    # TODO: error handling, if curl requests fails
    for line in r.content.split("\n"):
        if "\"number_of_replicas\" : " in line:
            value = line.split(":")[1]
            value = value.replace(" ", "").replace("\"", "").replace(",", "")
            number_of_replicas = int(value)
    if number_of_replicas == -1:
        raise Exception("Error: fail to get index replica for %s." % (index_name))
    return number_of_replicas
    
def confirm_es_replica_count(es_host, es_port, es_index_list, min_replica_count):
    # Check all ES indices have more than $min_replica_count replicas
    failed_index_list = []
    for index_name in es_index_list:
        number_of_replicas = get_es_replica_count(es_host, es_port, index_name)
        if number_of_replicas < min_replica_count:
            print "ERROR: index(%s) only has %d replicas, less than %d." \
                % (index_name, number_of_replicas, min_replica_count)
            failed_index_list.append(index_name)
    return failed_index_list

if __name__ == '__main__':
    # get parameters from users
    parser = argparse.ArgumentParser()
    parser.add_argument('--es_host', required=False, \
                        help="server ip or hostname for elasticsearch instance. Default value is ip of eth0", type=str)
    parser.add_argument('--es_port', default='9200', required=False, \
                        help="server port for elasticsearch instance", type=str)
    parser.add_argument('--min_replica_count', default='1', required=False, \
                        help="minimal replica each elasticsearch index should have", type=str)
    l = parser.parse_args()

    es_port = l.es_port
    min_replica_count = l.min_replica_count
    es_host = l.es_host
    # get ip of eth0, if es_host is not given
    if es_host is None:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        es_host = s.getsockname()[0]

    print "get es index list"
    es_index_list = get_es_index_list(es_host, es_port)

    print "confirm all indices has no less than %d replicas. \n Problematic Indices:" % (min_replica_count)
    failed_index_list = confirm_es_replica_count(es_host, es_port, es_index_list, min_replica_count)

    if len(failed_index_list) != 0:
        print "ERROR: Below indices don't have enough replica. %s" % \
            (",".join(failed_index_list))
    # TODO: enable nagios compatible
## File : check_elasticsearch_replica.py ends

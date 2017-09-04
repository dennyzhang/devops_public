#!/usr/bin/python
##-------------------------------------------------------------------
## File : es_backup.py
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description : Elasticsearch Backup By ES Snapshot feature
## --
## Created : <2016-08-01>
## Updated: Time-stamp: <2017-09-04 18:55:32>
##-------------------------------------------------------------------
# TODO: move to common library
import os
from datetime import date
import calendar
import subprocess

from elasticsearch import Elasticsearch

log_folder = "%s/log" % (os.path.expanduser('~'))
if os.path.exists(log_folder) is False:
    os.makedirs(log_folder)
log_file = "%s/%s.log" % (log_folder, os.path.basename(__file__).rstrip('\.py'))
# setup logging
from logging.handlers import RotatingFileHandler
import logging
format = "%(asctime)s %(filename)s:%(lineno)d - %(levelname)s: %(message)s"
formatter = logging.Formatter(format)
log = logging.getLogger('cbbackup')

Rthandler = RotatingFileHandler(log_file, maxBytes=5*1024*1024,backupCount=5)
Rthandler.setLevel(logging.INFO)
Rthandler.setFormatter(formatter)
consoleHandler = logging.StreamHandler()
consoleHandler.setLevel(logging.INFO)
consoleHandler.setFormatter(formatter)
# log critical info to both console output and log files
log.setLevel(logging.INFO)
log.addHandler(consoleHandler)
log.addHandler(Rthandler)

################################################################################
# https://dzone.com/articles/introduction-elasticsearch-0

def list_es_indices():
    # curl http://all-in-one-DockerDeployAllInOne-32:9200/_cat/indices?v1
    return

def create_es_repository():
    # curl -X PUT http://all-in-one-DockerDeployAllInOne-32:9200/_snapshot/my_backup -d '{
    #     "type": "fs",
    #     "settings": {
    #         "location": "/data/backup/elasticsearch",
    #         "compress": true,
    #         "chunk_size": "10m"
    #     }
    # }'
    return

def create_es_snapshot():
    # curl -XPUT http://all-in-one-DockerDeployAllInOne-32:9200/_snapshot/my_backup/snapshot_1?wait_for_completion=true
    return

def es_backup_indices(index_list):
    # curl -XPUT http://all-in-one-DockerDeployAllInOne-32:9200/_snapshot/my_backup/snapshot_1 -d '{
    #     "indices": "master-index-e4010da4110ba377d100f050cb4440db,master-index-8cd6e43115e9416eb23609486fa053e3",
    #     "ignore_unavailable": "true"
    # }'
    return
################################################################################

if __name__=='__main__':
    print("TODO: to be implemented")
    log.info("Backup succeed for Elasticsearch.")
## File : es_backup.py ends

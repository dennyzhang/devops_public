# -*- coding: utf-8 -*-
#!/usr/bin/python
##-------------------------------------------------------------------
## @copyright 2015 DennyZhang.com
## File : diagnostic_jenkinsjob_slow.py
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
## --
## Created : <2016-01-15>
## Updated: Time-stamp: <2017-09-04 18:55:32>
##-------------------------------------------------------------------
import os, sys
import re
import sqlite3
import time

def load_job_console_output(sqlite_file, console_file):
    # parse output into entries, then load to sqlite db
    #   line_id, timestamp, time_interval_seconds, time_origin, line_content
    # Sample original output:
    #   <span class="timestamp"><b>10:35:05</b> </span>Building in workspace ...
    table_name = "parse_jenkins"
    print("Parse jenkins job output: %s\n" % (console_file))
    print("Load to db: %s, table name: %s" % (sqlite_file, table_name))
    lineMatch = re.compile(r'<span class="timestamp"><b>.*</b> </span>', flags=re.IGNORECASE)
    fieldMatch = re.compile(r'<span class="timestamp"><b>(.*)</b> </span>(.*)', flags=re.IGNORECASE)

    conn = sqlite3.connect(sqlite_file)
    c = conn.cursor()

    # TODO: check whether db and table exists
    try:
        # Creating a new SQLite table with 1 column
        c.execute('create table {tn} (line_id INTEGER PRIMARY KEY, timestamp INTEGER, time_interval_seconds INTEGER, time_origin text, line_content text)' \
              .format(tn=table_name))
    except:
        print("ERROR to create table")

    line_id = 0
    previous_seconds = 0
    with open(console_file,'r') as f:
        for row in f:
            obj = lineMatch.search(row)
            if obj is not None:
                matchObj = fieldMatch.search(row)
                # TODO: defensive code
                time_origin = str(matchObj.group(1))
                timestamp = int(time_string_to_seconds(time_origin))
                if previous_seconds == 0:
                    time_interval_seconds = 0
                else:
                    time_interval_seconds = timestamp - previous_seconds

                previous_seconds = timestamp
                line_content  = str(matchObj.group(2))
                # TODO: better way to escape
                line_content = line_content.replace("'", "\'")
                line_content = line_content.replace("\"", "\'")
                # TODO: cut the line shortedcode style
                try:
                    c.execute("INSERT OR IGNORE INTO {tn} (line_id, timestamp, time_interval_seconds, time_origin, line_content) VALUES ({line_id}, {timestamp}, {time_interval_seconds}, \"{time_origin}\", \"{line_content}\")".\
                              format(tn = table_name, line_id = line_id, timestamp = timestamp, time_interval_seconds = time_interval_seconds, time_origin = time_origin, line_content = line_content))
                except:
                    print("Warning: ERROR to insert record")
                    print("%s, %s, %s" % (time_interval_seconds, time_origin, line_content))
                    
                line_id += 1

    conn.commit()
    conn.close()

    if line_id == 0:
        print("ERROR: no records recognized. Make sure target Jenkins run has Jenkins timstamper plugin enabled.")
        sys.exit(-1)

def time_string_to_seconds(time_str):
    # TODO: defensive coding for unexpected input
    seconds = time.mktime(time.strptime(time_str, '%Y-%m-%d %H:%M:%S'))
    return seconds

def show_report(sqlite_file, top_count):
    print("\n=================================\n")
    print("The %s slowest steps:" % (top_count))
    conn = sqlite3.connect(sqlite_file)
    c = conn.cursor()
    table_name = "parse_jenkins"
    c.execute('SELECT time_interval_seconds, time_origin, line_content FROM {tn} order by time_interval_seconds desc limit {top_count}'.\
              format(tn=table_name, top_count=top_count))
    all_rows = c.fetchall()
    for row in all_rows:
        print("%s seconds: %s %s" % (row[0], row[1], row[2]))
    conn.close()

# Usage: python ./diagnostic_jenkinsjob_slow.py
if __name__=='__main__':
    console_file = os.environ.get('CONSOLE_FILE')
    sqlite_file = os.environ.get('SQLITE_FILE')
    top_count = os.environ.get('TOP_COUNT')

    load_job_console_output(sqlite_file, console_file)
    show_report(sqlite_file, top_count)
## File : diagnostic_jenkinsjob_slow.py ends

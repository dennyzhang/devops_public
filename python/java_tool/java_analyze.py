#!/usr/bin/python
##-------------------------------------------------------------------
## File : java_analyze.py
## Description :
## --
## Created : <2017-01-25>
## Updated: Time-stamp: <2017-07-18 10:18:59>
##-------------------------------------------------------------------
import sys, os
import argparse
import requests, json

################################################################################
# Common functions
def analyze_gc_logfile(gc_logfile, apikey):
    print("Call rest api to parse gc log: http://www.gceasy.io.")

    headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}
    url = "http://api.gceasy.io/analyzeGC?apiKey=%s" % (apikey)
    res = requests.post(url, data=open(gc_logfile, "r"), headers=headers)

    if res.status_code != 200:
        print("ERROR: http response is not 200 OK. status_code: %d. content: %s..." \
            % (res.status_code, res.content[0:40]))
        return False

    content = res.content
    l = json.loads(content)
    print("graphURL: %s" % (l["graphURL"]))

    if '"isProblem":true' in content:
        print("ERROR: problem is found.")
        return False

    return True

def analyze_jstack_logfile(jstack_logfile, apikey, min_runnable_percentage):
    print("Call rest api to parse java jstack log: http://www.fastthread.io.")

    headers = {'content-type': 'application/json', 'Accept-Charset': 'UTF-8'}
    url = "http://api.fastthread.io/fastthread-api?apiKey=%s" % (apikey)
    res = requests.post(url, data=open(jstack_logfile, "r"), headers=headers)

    if res.status_code != 200:
        print("ERROR: http response is not 200 OK. status_code: %d. content: %s..." \
            % (res.status_code, res.content[0:40]))
        return False

    content = res.content
    l = json.loads(content)
    threadstate = l["threadDumpReport"][0]["threadState"]
    threadcount_runnable = int(threadstate[0]["threadCount"])
    threadcount_waiting = int(threadstate[1]["threadCount"])
    threadcount_timed_waiting = int(threadstate[2]["threadCount"])
    threadcount_blocked = int(threadstate[3]["threadCount"])

    print("%d threads in RUNNABLE, %d in WAITING, %d in TIMED_WAITING, %d in BLOCKED." \
          % (threadcount_runnable, threadcount_waiting, threadcount_timed_waiting, threadcount_blocked))
    print("graphURL: %s" % (l["graphURL"]))
    threadcount_total = threadcount_runnable + threadcount_waiting + \
                        threadcount_timed_waiting + threadcount_blocked
    if (float(threadcount_runnable)/threadcount_total) < min_runnable_percentage:
        print("ERROR: only %s threads are in RUNNABLE state. Less than %s." % \
              ("{0:.2f}%".format(float(threadcount_runnable)*100/threadcount_total), \
               "{0:.2f}%".format(min_runnable_percentage*100)))
        return False

    return True

################################################################################
## Generate gc log: start java program with -Xloggc enabled
## Generate java jstack log: jstack -l $java_pid
##
## Sample: Run with environment variables.
##
##   # analyze gc logfile:
##   export JAVA_ANALYZE_ACTION="analyze_gc_logfile"
##   export JAVA_ANALYZE_LOGFILE="/tmp/gc.log"
##   export JAVA_ANALYZE_APIKEY="29792f0d-5d5f-43ad-9358..."
##   curl -L https://raw.githubusercontent.com/.../java_analyze.py | bash
##
##   # analyze jstack logfile:
##   export JAVA_ANALYZE_ACTION="analyze_jstack_logfile"
##   export JAVA_ANALYZE_LOGFILE="/tmp/jstack.log"
##   export JAVA_ANALYZE_APIKEY="29792f0d-5d5f-43ad-9358..."
##   curl -L https://raw.githubusercontent.com/.../java_analyze.py | bash
##
## Sample: Run with argument parameters.
##   python ./java_analyze.py --action analyze_gc_logfile \\
##            --logfile /tmp/gc.log --apikey "29792f0d..."
##   python ./java_analyze.py --action analyze_jstack_logfile \
##            --logfile /tmp/jstack.log --apikey "29792f0d..."
##
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--action', default='', required=False, \
                        help="Supported action: analyze_gc_logfile or analyze_jstack_logfile", \
                        type=str)
    parser.add_argument('--logfile', default='', required=False, \
                        help="Critical log file to parse", type=str)
    parser.add_argument('--apikey', default='', required=False, \
                        help="API key to call gceasy.io and fastthread.io", \
                        type=str)
    parser.add_argument('--minrunnable', default=0.40, required=False, \
                        help="If too many threads are not in RUNNABLE state, we raise alerts", \
                        type=float)

    l = parser.parse_args()
    action = l.action
    logfile = l.logfile
    apikey = l.apikey
    # Get parameters via environment variables, if missing
    if action == "" or action is None:
        action = os.environ.get('JAVA_ANALYZE_ACTION')
    if logfile == "" or logfile is None:
        logfile = os.environ.get('JAVA_ANALYZE_LOGFILE')
    if apikey == "" or apikey is None:
        apikey = os.environ.get('JAVA_ANALYZE_APIKEY')

    # input parameters check
    if action == "" or action is None:
        print("ERROR: mandatory parameter of action is not given.")
        sys.exit(1)
    if logfile == "" or logfile is None:
        print("ERROR: mandatory parameter of logfile is not given.")
        sys.exit(1)
    if apikey == "" or apikey is None:
        print("ERROR: mandatory parameter of apikey is not given.")
        sys.exit(1)

    ############################################################################
    # main logic
    if action == "analyze_gc_logfile":
        if analyze_gc_logfile(logfile, apikey) is False:
            print("ERROR: problems are detected in gc log(%s)." % (logfile))
            sys.exit(1)
        else:
            print("OK: no problem found when parsing gc log(%s)." % (logfile))
    elif action == "analyze_jstack_logfile":
        if analyze_jstack_logfile(logfile, apikey, l.minrunnable) is False:
            print("ERROR: problems are detected in jstack log(%s)." % (logfile))
            sys.exit(1)
        else:
            print("OK: no problem found when parsing jstack log(%s)." % (logfile))
    else:
        print("ERROR: not supported action(%s)." % (action))
        sys.exit(1)
## File : java_analyze.py ends

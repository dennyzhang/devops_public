#!/usr/bin/python
##-------------------------------------------------------------------
## File : examine_full_gc_frequency.py
## Description : If too many full GC has happened recently, raise alerts
## --
## Created : <2017-07-25>
## Updated: Time-stamp: <2017-07-25 18:13:43>
##-------------------------------------------------------------------
import sys, os
import argparse
import requests, json

SYS_EXIT_WARN = 1
SYS_EXIT_CRI = 2
SYS_EXIT_OK = 0
################################################################################
# https://stackoverflow.com/questions/136168/get-last-n-lines-of-a-file-with-python-similar-to-tail
def tail(f, lines=20):
    total_lines_wanted = lines

    BLOCK_SIZE = 1024
    f.seek(0, 2)
    block_end_byte = f.tell()
    lines_to_go = total_lines_wanted
    block_number = -1
    blocks = [] # blocks of size BLOCK_SIZE, in reverse order starting
                # from the end of the file
    while lines_to_go > 0 and block_end_byte > 0:
        if (block_end_byte - BLOCK_SIZE > 0):
            # read the last block we haven't yet read
            f.seek(block_number*BLOCK_SIZE, 2)
            blocks.append(f.read(BLOCK_SIZE))
        else:
            # file too small, start from begining
            f.seek(0,0)
            # only read what was not read
            blocks.append(f.read(block_end_byte))
        lines_found = blocks[-1].count('\n')
        lines_to_go -= lines_found
        block_end_byte -= BLOCK_SIZE
        block_number -= 1
    all_read_text = ''.join(reversed(blocks))
    return '\n'.join(all_read_text.splitlines()[-total_lines_wanted:])


def count_pattern_in_log_tail(fname, tail_log_count, pattern_string):
    count = 0

    with open(fname,'r') as f:
        message = tail(f, tail_log_count)
        # Escape double quotes for JSON
        for line in message.spli("\n"):
            if pattern_string in line:
                count = count + 1
    return count

############################################################################
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--gc_logfile', required=True, \
                        help="Tail log file", type=str)
    parser.add_argument('--tail_log_num', required=False, default=100,\
                        help="Tail last multiple lines of log file", type=int)
    parser.add_argument('--warning_gc_count', required=False, default=5,\
                        help="If GC count over than this, but lower than --critical_gc_count, quit with warning", \
                        type=int)
    parser.add_argument('--critical_gc_count', required=False, default=10,\
                        help="If GC count over than this, quit with error", \
                        type=int)
    l = parser.parse_args()
    pattern_string = "Full GC"

    try:
        pattern_count = count_pattern_in_log_tail(l.gc_logfile, l.tail_log_num, pattern_string)
        if pattern_count >= l.critical_gc_count:
            print "ERROR: %d full gc has happened in last %d lines of %s|full_gc_count=%d"  \
                % (pattern_count, l.tail_log_num, l.gc_logfile, pattern_count)
            sys.exit(SYS_EXIT_CRI)

        if pattern_count >= l.warning_gc_count:
            print "WARNING: %d full gc has happened in last %d lines of %s|full_gc_count=%d"  \
                % (pattern_count, l.tail_log_num, l.gc_logfile, pattern_count)
            sys.exit(SYS_EXIT_WARN)

        print "OK: %d full gc has happened in last %d lines of %s|full_gc_count=%d"  \
            % (pattern_count, l.tail_log_num, l.gc_logfile, pattern_count)
        sys.exit(SYS_EXIT_OK)
    except Exception as e:
        print "ERROR: Fail to get gc count: %s" % (e)
        sys.exit(SYS_EXIT_CRI)
## File : examine_full_gc_frequency.py ends

#!/usr/bin/python
##-------------------------------------------------------------------
## File : examine_full_gc_frequency.py
## Description : If too many full GC has happened recently, raise alerts
## --
## Created : <2017-07-25>
## Updated: Time-stamp: <2017-07-25 17:51:38>
##-------------------------------------------------------------------
import sys, os
import argparse
import requests, json

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

def count_full_gc_from_logfile(gc_logfile, tail_log_count = 100):
    full_gc_count = 0
    full_gc_pattern = "Full GC"

    with open(gclog_file,'r') as f:
        message = tail(f, tail_log_count)
        # Escape double quotes for JSON
        for line in message.spli("\n"):
            if full_gc_pattern in line:
                full_gc_count = full_gc_count + 1
    return full_gc_count


############################################################################
# main logic
sys.exit(1)
## File : examine_full_gc_frequency.py ends

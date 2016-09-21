#!/bin/bash
command="ssh root@104.131.129.100 ls /tmp/abab"
echo "$command"
$command
echo "should not print"

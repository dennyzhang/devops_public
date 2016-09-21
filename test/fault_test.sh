#!/bin/bash
#!/bin/bash -ex
function shell_exit() {
    errcode=$?
    if [ $errcode -eq 0 ]; then
        log "Action succeeds."
    else
        log "Action Fails."
    fi
    exit $errcode
}

trap shell_exit SIGHUP SIGINT SIGTERM 0

command="ssh root@104.131.129.100 ls /tmp/abab"
echo "$command"
$command
echo "should not print"

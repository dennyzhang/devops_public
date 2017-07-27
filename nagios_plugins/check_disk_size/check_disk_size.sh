#!/bin/sh
#
# ## Plugin for Nagios to monitor directory size
# ## Written by Gerd Stammwitz (http://www.enbiz.de/)
# ##
# ## - 20040727 coded and tested for Solaris and Linux
# ## - 20041216 published on NagiosExchange
# ## - 20070710 modified by Jose Vicente Mondejar to add perfdata option
#
#
# ## You are free to use this script under the terms of the Gnu Public License.
# ## No guarantee - use at your own risc.
#
#
# Usage: ./check_dirsize -d <path> -w <warn> -c <crit>
#
# ## Description:
#
# This plugin determines the size of a directory (including sub dirs)
# and compares it with the supplied thresholds.
# It might also be used to monitor a regular file instead of a directory.
#
# ## Output: 
#
# The plugin prints the size of the directory in KB followed by "ok" or
# either "warning" or "critical" if the corresponing threshold is reached.
#
# Exit Codes
# 0 OK       Directory size checked and everything is ok
# 1 Warning  Directory size above "warning" threshold
# 2 Critical Directory size above "critical" threshold
# 3 Unknown  Invalid command line arguments or could not determine directory size
#
# Example: check_dirsize -d . -w 1000 -c 1400
#
# 121 KB - ok         (exit code 0)
# 1234 KB - warning   (exit code 1)
# 1633 KB - critical  (exit code 2)


# Paths to commands used in this script.  These
# may have to be modified to match your system setup.

PATH=""

DU="/usr/bin/du"
CUT="/usr/bin/cut"
WC="/usr/bin/wc"

PROGNAME=`/usr/bin/basename $0`
PROGPATH=`echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION="Revision 1.1"
AUTHOR="(c) 2004,2007 Gerd Stammwitz (http://www.enbiz.de/)"

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

print_revision() {
    echo "$REVISION $AUTHOR"
}

print_usage() {
    echo "Usage: $PROGNAME -d|--dirname <path> [-w|--warning <warn>] [-c|--critical <crit>] [-f|--perfdata]"
    echo "Usage: $PROGNAME -h|--help"
    echo "Usage: $PROGNAME -V|--version"
    echo ""
    echo "<warn> and <crit> must be expressed in KB"
}

print_help() {
    print_revision $PROGNAME $REVISION
    echo ""
    echo "Directory size monitor plugin for Nagios"
    echo ""
    print_usage
    echo ""
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
    print_usage
    exit $STATE_UNKNOWN
fi

# Grab the command line arguments

thresh_warn=""
thresh_crit=""
perfdata=0
exitstatus=$STATE_WARNING #default
while test -n "$1"; do
    case "$1" in
        --help)
            print_help
            exit $STATE_OK
            ;;
        -h)
            print_help
            exit $STATE_OK
            ;;
        --version)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        -V)
            print_revision $PROGNAME $VERSION
            exit $STATE_OK
            ;;
        --dirname)
            dirpath=$2
            shift
            ;;
        -d)
            dirpath=$2
            shift
            ;;
        --warning)
            thresh_warn=$2
            shift
            ;;
        -w)
            thresh_warn=$2
            shift
            ;;
        --critical)
            thresh_crit=$2
            shift
            ;;
        -c)
            thresh_crit=$2
            shift
            ;;
        -f)
            perfdata=1
            ;;
        -perfdata)
            perfdata=1
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

##### Get size of specified directory

error=""
duresult=`$DU -sk $dirpath 2>&1` || error="Error"
if [ ! "$error" = "" ]; then
    errtext=`echo $duresult | $CUT -f3 -d":"`
    echo "$error:$errtext"
    exit $STATE_UNKNOWN
fi

dirsize=`echo $duresult | $CUT -f1 -d" "`
result="ok"
exitstatus=$STATE_OK

##### Compare with thresholds

if [ "$thresh_warn" != "" ]; then
    if [ $dirsize -ge $thresh_warn ]; then
        result="warning"
        exitstatus=$STATE_WARNING
    fi
fi
if [ "$thresh_crit" != "" ]; then
    if [ $dirsize -ge $thresh_crit ]; then
        result="critical"
        exitstatus=$STATE_CRITICAL
    fi
fi
if [ $perfdata -eq 1 ]; then
    result="$result|'size'=${dirsize}KB;${thresh_warn};${thresh_crit}"
fi

echo "$dirsize KB - $result"
exit $exitstatus

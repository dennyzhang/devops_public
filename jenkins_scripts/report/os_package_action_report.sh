#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v1/LICENSE
##
## File : os_package_action_report.sh
## Author : DennyZhang.com <contact@dennyzhang.com>
## Description :
##
## --
## Created : <2016-04-03>
## Updated: Time-stamp: <2017-09-04 18:54:37>
##-------------------------------------------------------------------
################################################################################################
## env variables:
##     ssh_server: 192.168.1.3:2704:root
##     env_parameters:
##         export HAS_INIT_ANALYSIS=false
##         export PARSE_MAXIMUM_ENTRIES="500"
##         export OS_VERSION="ubuntu-14.04"
################################################################################################
. /etc/profile
[ -n "$DOWNLOAD_TAG_NAME" ] || export DOWNLOAD_TAG_NAME="tag_v6"
export DOWNLOAD_PREFIX="https://raw.githubusercontent.com/DennyZhang/devops_public/${DOWNLOAD_TAG_NAME}"
if [ ! -f /var/lib/devops/refresh_common_library.sh ]; then
    [ -d /var/lib/devops/ ] || (sudo mkdir -p /var/lib/devops/ && sudo chmod 777 /var/lib/devops)
    wget -O /var/lib/devops/refresh_common_library.sh "$DOWNLOAD_PREFIX/common_library/refresh_common_library.sh"
    chmod 777 /var/lib/devops/refresh_common_library.sh
fi
bash /var/lib/devops/refresh_common_library.sh "3536991806" "/var/lib/devops/devops_common_library.sh" \
     "${DOWNLOAD_PREFIX}/common_library/devops_common_library.sh"
. /var/lib/devops/devops_common_library.sh
################################################################################################
function generate_package_log_file() {
    local working_dir=${1?}
    local action_log_file=${2?}

    cat > /tmp/copy_package_log.sh <<EOF
#!/bin/bash -e
working_dir="$working_dir"
action_log_file="$action_log_file"
rm -rf \$working_dir
mkdir -p \$working_dir

> $action_log_file
cd /var/log/apt
echo "Copy /var/log/apt/history.log* to \$action_log_file"
for f in \$(ls -rt history.log*); do
 cp \$f \$working_dir/
 if [[ "\${f}" == *.gz ]]; then
 gzip -d \$working_dir/\$f
 f=\${f%.gz}
 fi
 cat \$working_dir/\$f >> \$action_log_file
done
EOF
    echo "Upload /tmp/copy_package_log.sh"
    scp -i "$ssh_key_file" -P "$server_port" -o StrictHostKeyChecking=no /tmp/copy_package_log.sh \
        "$ssh_username@$server_ip:/tmp/copy_package_log.sh"

    $SSH_CONNECT "bash -e /tmp/copy_package_log.sh"
}

function show_package_report() {
    local action_log_file=${1?}
    local entry_num=${2?}
    ssh_command="tail -n $entry_num $action_log_file"
    echo "$ssh_command"
    $SSH_CONNECT "$ssh_command"
    echo ""
}

function skip_safe_package() {
    # skip safe packages from the given list
    local os_version=${1?}
    local package_list=${2?}

    for package in $(safe_package_list "$os_version"); do
        package_list=$(echo -e "$package_list" | grep -v "^${package}: ")
    done
    echo -e "$package_list"
}

function safe_package_list() {
    # whitelist of safe package
    local os_version=${1?}
    case "$os_version" in
        ubuntu-14.04)
            package_list="apt apt-utils base-files bc bsdutils build-essential \
coreutils cpio curl dpkg e2fslibs e2fsprogs gcc-4.8 gcc-4.9-base git git-core \
gnupg gpgv htop ifupdown initramfs-tools initramfs-tools-bin inotify-tools \
libapt-inst1.5 libapt-pkg4.12 libblkid1 libc-bin libc6 libcgmanager0 libcomerr2 \
libcurl3 libdrm2 libgcc1 libgcrypt11 libgnutls-openssl27 libgnutls26 libmount1 \
libpython3.4-minimal libpython3.4-stdlib libss2 libssl1.0.0 libtasn1-6 libudev1 \
libuuid1 lsb-release lsof mount multiarch-support netcat ntpdate openssh-client \
openssh-server openssl python3.4 python3.4-minimal rsyslog strace sudo sysstat \
tar tcpdump telnet tmux tree tzdata udev unzip util-linux vim wget zip";;
        *)
            echo "ERROR: Not supported OS: $os_versoin"
            exit 1
            ;;
    esac
    echo "$package_list"
}

function get_current_package_list() {
    ssh_command="dpkg -l"
    package_list=$($SSH_CONNECT "$ssh_command")
    errcode=$?
    if [ $errcode -ne 0 ]; then
        # TODO: better way to report output
        echo "ERROR: fail to run $ssh_command"
        exit 1
    fi
    package_list=$(ubuntu_parse_package_list "$package_list")
    echo -e "$package_list"
}

function detect_new_installed_packages() {
    local os_version=${1?}
    package_file="/tmp/${os_version}.txt"

    # get default package list
    get_default_package_list "$os_version" "$package_file"
    default_package_list=$(cat "$package_file")
    default_package_list=$(ubuntu_parse_package_list "$default_package_list")

    # TODO: defensive coding
    # get current package list
    current_package_list=$(get_current_package_list)

    # echo -e "default_package_list: ${default_package_list}"
    # echo -e "current_package_list: ${current_package_list}"

    # detect new installed packages
    new_installed_package_list=""
    IFS=$'\n'
    for package in $current_package_list; do
        unset IFS
        if [[ "$default_package_list" != *"$package"* ]]; then
            new_installed_package_list="${new_installed_package_list}\n${package}"
        fi
    done

    new_installed_package_list=$(skip_safe_package "$os_version" "$new_installed_package_list")
    echo -e "\n========== New Installed Uncommon Packages:$new_installed_package_list"

    package_count=$(echo -e "$new_installed_package_list" | wc -l)
    package_count=$(string_strip_whitespace "$package_count")
    echo -e "\n========== New Installed Uncommon Package Count: $package_count"
}

function shell_exit() {
    errcode=$?
    exit $errcode
}
################################################################################################
trap shell_exit SIGHUP SIGINT SIGTERM 0
source_string "$env_parameters"

[ -n "$ssh_key_file" ] || ssh_key_file="$HOME/.ssh/id_rsa"
[ -n "$PARSE_MAXIMUM_ENTRIES" ] || PARSE_MAXIMUM_ENTRIES="500"
[ -n "$HAS_INIT_ANALYSIS" ] || HAS_INIT_ANALYSIS=false
[ -n "$WORKING_DIR" ] || WORKING_DIR=/tmp/package_log
[ -n "$OS_VERSION" ] || OS_VERSION="ubuntu-14.04"

ACTION_LOG_FILE="$WORKING_DIR/package_action.log"

# Input Parameters check
check_list_fields "IP:TCP_PORT:STRING" "$ssh_server"
enforce_ssh_check "true" "$ssh_server" "$ssh_key_file"

server_split=(${ssh_server//:/ })
server_ip=${server_split[0]}
server_port=${server_split[1]}
ssh_username=${server_split[2]}

[ -n "$ssh_username" ] || ssh_username="root"

SSH_CONNECT="ssh -i $ssh_key_file -p $server_port -o StrictHostKeyChecking=no $ssh_username@$server_ip"

if [ "$HAS_INIT_ANALYSIS" = "false" ]; then
    generate_package_log_file "$WORKING_DIR" "$ACTION_LOG_FILE"
fi

echo -e "\n========== Package Installation Log:"
show_package_report "$ACTION_LOG_FILE" "$PARSE_MAXIMUM_ENTRIES"

output=$(get_current_package_list "$OS_VERSION")
if echo -e "$output" | grep "ERROR: "; then
    "Skip detecting what new packages installed since pure OS installation"
else
    detect_new_installed_packages "$OS_VERSION"
fi
## File : os_package_action_report.sh ends

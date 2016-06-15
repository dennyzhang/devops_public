#!/bin/bash -e
##-------------------------------------------------------------------
## @copyright 2016 DennyZhang.com
## Licensed under MIT
## https://raw.githubusercontent.com/DennyZhang/devops_public/master/LICENSE
##
## File : inject_kitchen_ci_key.sh
## Author : Denny <denny@dennyzhang.com>
## Description :
## --
## Created : <2016-04-20>
## Updated: Time-stamp: <2016-06-15 11:52:18>
##-------------------------------------------------------------------
if [ -d .kitchen ]; then
    echo "Inject ssh key for Kitchen CI test: .kitchen/docker_id_rsa and .kitchen/docker_id_rsa.pub"
    cat > .kitchen/docker_id_rsa <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwMKevWSAPFLM+RIEoeYAVyhhWQVGsD/Jw0oGVVulZf/jQ4Yo
+RKOQXj2L1GsYP+Whca8UTjsixhPcYTQZOzz+PSM9aajvU/0DUiIrrr0P14ab2+D
kHw+ca+peLf/YC3/jmBr2hR3/8czJ3PXCs2fmsy5Qx23nsLtRjCP1zRVqOFVgLB/
usTPFSKXSUmke2pSZ/1unZskQW5NLkt2Lret41RZOM2pQM16rlNAV9Z3vgywfy1v
GWpzeT1hAmm0ouHV2C38Qtqw4Q3EHV1NzMFeW+07UeaxaDUvCBnMh6HqubWrALQA
Gg9rBM8iW5ZQHxbDcsTUPmIfPd+R3Fqsdv09KwIDAQABAoIBAHbWha8Vysll8uCL
bzew6PzS9FFBo3b9nJI9jPIK8kmUHLSAfbow6msK/BvoKnISoOYQxAD/KzYF4tSF
oUTXoQIXIuA/wCryo++cjEfNEtAOYBXbliz5rDXCqqS2K0dMlIVehJ+KhwC1+p+U
Fzud0YxKMt1h8NZ8LnRbdBKlPTpDv7OHwN/UXzkNJRThYgoGHhMOEQkFG0u/WOxp
6fFsibXydKI/RywZRO4iDzJgcN8WFMl2UrbOhhpYpHtJN42Sno4VtPUUtyoqH5yI
YF7SAyEQXYw3Rhh4ZvigC0ADy1KUqWRcDdng+wDcgQ+WqqMR9HV0OteLFlrriBds
wuz5c2ECgYEA5hUH5oogTJpdkvuettGrYhBPC/bB2TVPzDKZfB1FVppa02BrwoAh
BmTp7FNhr65EvU3p+lah3ztIt5PZ/v1n1pJC0qgMK689yellJx588u8OgbjTCdx9
IsKzrGpBrHSi3PKIjr7SvxuWseqd7LAdOUBiNyubYBzCtOg6h4j4uGUCgYEA1nlS
jYjOfELiOZbLgJYNdDmyxPERYKKR5BRwODDID1fMxjbxCRKINK1S8OTnuK5KCqn1
F1xpQSIpSJFFnGlSSEJrYk6WLdDDEOT42uHAUHCSzZc4sVsEabu8hiZAnjuLUN/u
20g8g405isxpyfBnJ92hY4s5apGnUuLPaJzWnk8CgYEAwJSj20SMCnI+lpOD4lQX
Fmq+Ly5oTO2BkFJeA/PgIL/r+/c92zwx6E85OTUFk+3S3XzEtmQi812E3RulIPhs
HL6prfc40KvKlSGFKDwtq42K3+uawStLlnfPuiXqOHYcB8H9qTVx4sIt3Veavg0f
ONd6HeGjGMyZ8KBctSthu70CgYBxSvczso+4jjAoUaLAEwOaYJwxclJGpLnCLJW2
6PXVPQD7t6wNqc9vXBtTCufo45BTH8JLC9LByETcg3itDemcKBHHhVHJc9yHARz/
qn7HPyAdIAOflD+5hqUoi+5YZ4XJO/FVvkvRBfneeupq9OXY5jdJeRLkW3pyy0La
tPad+wKBgFHujuxvbxX5uZVxhOIB/kOTW7HSG26Nra/efwAsPf9BqiqxetWnEtqc
IDD/IW+xRsS1TdY9fgBfgxfm7XXGBbwrbkWsuIyMVvXjBlrIMIzzPM0ag8XklrWt
jfIrnQrjfUwCBDacxFLGvWpMh22aCxYWU5pCRlknQtULRiYpUdtH
-----END RSA PRIVATE KEY-----
EOF

    chmod 400 .kitchen/docker_id_rsa

    cat >.kitchen/docker_id_rsa.pub <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAwp69ZIA8Usz5EgSh5gBXKGFZBUawP8nDSgZVW6Vl/+NDhij5Eo5BePYvUaxg/5aFxrxROOyLGE9xhNBk7PP49Iz1pqO9T/QNSIiuuvQ/Xhpvb4OQfD5xr6l4t/9gLf+OYGvaFHf/xzMnc9cKzZ+azLlDHbeewu1GMI/XNFWo4VWAsH+6xM8VIpdJSaR7alJn/W6dmyRBbk0uS3Yut63jVFk4zalAzXquU0BX1ne+DLB/LW8ZanN5PWECabSi4dXYLfxC2rDhDcQdXU3MwV5b7TtR5rFoNS8IGcyHoeq5tasAtAAaD2sEzyJbllAfFsNyxNQ+Yh8935HcWqx2/T0r denny.zhang001@gmail.com
EOF
else
    echo "Warning: inject kitchen ci key fails, since .kitchen directory not found"
fi
## File : inject_kitchen_ci_key.sh ends

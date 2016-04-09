# inject_ssh_key
Inject ssh key to ~/$user/.ssh/authorized_keys
- We can add the ssh key to multiple users
- If .ssh directory is missing, it will be created automatically.

How To Use
==========
```
user_home_list='mac:/Users/mac,root:/root'
ssh_email='denny@dennyzhang.com'
ssh_key='AAAAB3NzaC1yc2EAAAADAQABAAABAQDAwp69ZIA8Usz5EgSh5gBXKGFZBUawP8nDSgZVW6Vl/+NDhij5Eo5BePYvUaxg/5aFxrxROOyLGE9xhNBk7PP49Iz1pqO9T/QNSIiuuvQ/Xhpvb4OQfD5xr6l4t/9gLf+OYGvaFHf/xzMnc9cKzZ+azLlDHbeewu1GMI/XNFWo4VWAsH+6xM8VIpdJSaR7alJn/W6dmyRBbk0uS3Yut63jVFk4zalAzXquU0BX1ne+DLB/LW8ZanN5PWECabSi4dXYLfxC2rDhDcQdXU3MwV5b7TtR5rFoNS8IGcyHoeq5tasAtAAaD2sEzyJbllAfFsNyxNQ+Yh8935HcWqx2/T0r'
wget -O inject_ssh_key.sh  https://raw.githubusercontent.com/DennyZhang/inject_ssh_key/master/inject_ssh_key.sh
sudo bash ./inject_ssh_key.sh $user_home_list $ssh_email $ssh_key
```

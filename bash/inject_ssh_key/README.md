# inject_ssh_key
Inject ssh key to ~/$user/.ssh/authorized_keys
- We can add the ssh key to multiple users
- If .ssh directory is missing, it will be created automatically.

How To Use
==========
```
user_home_list='mac:/Users/mac,root:/root'
ssh_email='contact@dennyzhang.com'
ssh_key='AAAAB3NzaC1yc2EAAAADAQABAAABAQDAwp69ZIA8Usz5EgSh5gBXKGFZBUawP8nDSgZVW6Vl...'
wget -O inject_ssh_key.sh  https://raw.githubusercontent.com/DennyZhang/devops_public/tag_v6/bash/inject_ssh_key/inject_ssh_key.sh
sudo bash ./inject_ssh_key.sh $user_home_list $ssh_email $ssh_key
```

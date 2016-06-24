Update Common Library Checksum 
==============================
cd /Users/mac/baidu/百度云同步盘/private_data/project/devops_consultant/consultant_code/devops_public/jenkins_ci
find . -name "*.sh" | xargs sed  -i "" "s/3543853840/1448253646/g"
find . -name "*.sh" | xargs grep "bash /var/lib/devops/refresh_common_library.sh"

Copy folder
==============================
dst_dir="/Users/mac/baidu/百度云同步盘/private_data/work/totvs/totvs_code/mdmpublic/common_bash"
cd $dst_dir
rm -rf *

cd /Users/mac/baidu/百度云同步盘/private_data/project/devops_consultant/consultant_code/devops_public/jenkins_ci
for d in $(find . -type d -maxdepth 1 | grep -v .git | grep -v "^\.$"); do
    command="/bin/cp -r $d $dst_dir/"
    echo $command
    $command 
done

cd $dst_dir
git status

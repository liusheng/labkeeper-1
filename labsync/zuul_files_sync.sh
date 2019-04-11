#!/bin/bash -ex
# Copyright 2015 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

github_username=$1
github_useremail=$2
github_token=$3
deploy_type=${4:-openlab}

online_file=~/inotify/labkeeper/etc/zuul/${deploy_type}-main.yaml

set -e

# the default path of cron is /usr/bin:/bin, add hub path to PATH
export PATH=/usr/local/bin:$PATH

# prepare for sync
bash /home/ubuntu/sync_prepare.sh ${github_username} ${github_useremail} ${github_token}

cd ~/inotify/labkeeper/
hub checkout master
hub pull
modify_time=`date +%Y%m%d%H%M`
branch_name="update${modify_time}"
message="[Zuul_Sync] Sync_${modify_time}_modified_by_${github_username}"
hub checkout -b ${branch_name}
echo "copy file to labkeeper"
cp /etc/zuul/main.yaml $online_file

is_modified="`hub status |grep modified`"
if [[ $is_modified ]];then
    hub add $online_file
    hub commit -m "${message}"
    hub push origin ${branch_name}
    # using hub to create pull-request
    ## avoid being prompted username and password when execute cmd 'hub pull-request'
    export GITHUB_TOKEN=${github_token}
    hub pull-request -m "${message}"
    echo "Create pull request to theopenlab/labkeeper success!"
    hub checkout master
    hub branch -D ${branch_name}
fi

#!/bin/bash
# Copyright (C) <2014,2015>  <Ding Wei>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Change log
# 170627 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export SEED=$RANDOM

export RUN_PATH=$(dirname $0)
export BFG='java -jar /local/ibuild/bin/bfg-1.12.15.jar'

[[ -d $1 ]] && pushd $1
$RUN_PATH/find_git_big_file.sh >/tmp/big_file.$SEED.tmp

SPLIT_LINE()
{
 echo -e "============================== $1"
}

for FILE_URL in $(cat /tmp/big_file.$SEED.tmp | grep -v Size | awk -F' ' {'print $4'} | sort -u)
do
    [[ $(file $FILE_URL | grep ASCII) ]] || export FILE_CHECK=BIN
    export FILE_NAME=$(basename $FILE_URL)
    if [[ ! -f $FILE_URL && $FILE_CHECK = BIN ]] ; then
        SPLIT_LINE "delete $FILE_URL"
        $BFG --delete-files $FILE_NAME ./
    elif [[ $FILE_CHECK = BIN ]] ; then
        SPLIT_LINE "Keep latest $FILE_URL"
        $BFG -p HEAD -D $FILE_NAME ./
    else
        SPLIT_LINE "None binary file, No Change"
    fi
done

git reflog expire --expire=now --all && git gc --prune=now --aggressive

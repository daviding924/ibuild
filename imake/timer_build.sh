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
# 150128 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export USER=$(whoami)
export TASK_SPACE=/dev/shm
export TOHOUR=$(date +%H)
export SEED=$RANDOM
export TOYMD=$(date +%Y%m%d)
export BEFORE_TOYMD=$(date +%Y%m%d --date="$TOYMD 1 days ago")

export IBUILD_ROOT=$HOME/ibuild
    [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=$(dirname $0 | awk -F'/ibuild' {'print $1'})'/ibuild'
if [[ ! -e $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi
export SVN_SRV_IBUILD=$(grep '^SVN_SRV_IBUILD=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'SVN_SRV_IBUILD=' {'print $2'})
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
export SVN_SRV_ISPEC=$(grep '^SVN_SRV_ISPEC=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'SVN_SRV_ISPEC=' {'print $2'})
    [[ -z $SVN_SRV_ISPEC ]] && export SVN_SRV_ISPEC=$SVN_SRV_IBUILD
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

if [[ $(cat $LOCK_SPACE/timer_build.lock 2>/dev/null) != $TOHOUR ]] ; then
    echo $TOHOUR >$LOCK_SPACE/timer_build.lock
else
    exit
fi

svn co -q $IBUILD_SVN_OPTION svn://$SVN_SRV_IBUILD/ispec/ispec $TASK_SPACE/tmp.ispec.$SEED

CLEAN_TASK_STACK()
{
 if [[ -e ~/svn/itask/tasks && -e /dev/shm/lock && -e /local/queue/itask ]] ; then
    pushd ~/svn/itask/tasks
    for TASK_NAME in $(grep merged *|awk -F':' {'print $1'})
    do
        TASK_REV=$(svn info $TASK_NAME | grep 'Rev:' | awk -F' ' {'print $4'})
        rm -f /dev/shm/lock/itask-r$TASK_REV.* /local/queue/itask/*.$TASK_REV >/dev/null 2>&1
    done
    popd
 fi
}

if [[ -e $TASK_SPACE/tmp.ispec.$SEED/timer/$TOHOUR.spec ]] ; then
    for SPEC_FILTER in $(cat $TASK_SPACE/tmp.ispec.$SEED/timer/$TOHOUR.spec | sort -u)
    do
        for SPEC_NAME in $(ls $TASK_SPACE/tmp.ispec.$SEED/spec | grep $SPEC_FILTER)
        do
            cp $TASK_SPACE/tmp.ispec.$SEED/spec/$SPEC_NAME $TASK_SPACE/tmp.ispec.$SEED/normal.$SPEC_NAME
            [[ ! $(grep 'IBUILD_MODE=' $TASK_SPACE/tmp.ispec.$SEED/normal.$SPEC_NAME) ]] && echo "IBUILD_MODE=normal" >>$TASK_SPACE/tmp.ispec.$SEED/normal.$SPEC_NAME && CLEAN_TASK_STACK
            $IBUILD_ROOT/imake/add_task.sh $TASK_SPACE/tmp.ispec.$SEED/normal.$SPEC_NAME
        done
    done
fi

if [[ -e $TASK_SPACE/tmp.ispec.$SEED/timer/$TOHOUR.spec.bundle ]] ; then
    for SPEC_FILTER in $(cat $TASK_SPACE/tmp.ispec.$SEED/timer/$TOHOUR.spec.bundle | sort -u)
    do
        for SPEC_NAME in $(ls $TASK_SPACE/tmp.ispec.$SEED/spec | grep $SPEC_FILTER)
        do
            export IBUILD_GRTSRV=$(grep '^IBUILD_GRTSRV=' $TASK_SPACE/tmp.ispec.$SEED/spec/$SPEC_NAME | awk -F'IBUILD_GRTSRV=' {'print $2'} | awk -F':' {'print $1'})
            export IBUILD_GRTSRV_PROJECT_BRANCH=$(grep '^IBUILD_GRTSRV_PROJECT_BRANCH=' $TASK_SPACE/tmp.ispec.$SEED/spec/$SPEC_NAME | awk -F'IBUILD_GRTSRV_PROJECT_BRANCH=' {'print $2'})
            export SORT_BUNDLE_GRTSRV_INFO="$IBUILD_GRTSRV:$IBUILD_GRTSRV_PROJECT_BRANCH"

            cp $TASK_SPACE/tmp.ispec.$SEED/spec/$SPEC_NAME $TASK_SPACE/tmp.ispec.$SEED/bundle.$SPEC_NAME
            echo "IBUILD_MODE=bundle" >>$TASK_SPACE/tmp.ispec.$SEED/bundle.$SPEC_NAME
            echo $BEFORE_TOYMD $SORT_BUNDLE_GRTSRV_INFO
            $IBUILD_ROOT/ichange/sort_24h_patch.sh $BEFORE_TOYMD $SORT_BUNDLE_GRTSRV_INFO | while read PATCH
            do
                echo BUNDLE_PATCH=$PATCH >>$TASK_SPACE/tmp.ispec.$SEED/bundle.$SPEC_NAME
            done

            if [[ $(grep '^BUNDLE_PATCH=' $TASK_SPACE/tmp.ispec.$SEED/bundle.$SPEC_NAME) ]] ; then
                $IBUILD_ROOT/imake/add_task.sh $TASK_SPACE/tmp.ispec.$SEED/bundle.$SPEC_NAME
            fi
        done
    done
fi

rm -fr $TASK_SPACE/tmp.ispec.$SEED



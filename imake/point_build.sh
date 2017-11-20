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
# 170427 Create by Ding Wei
source /etc/bash.bashrc
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export SEED=$RANDOM
export IBUILD_ROOT=$HOME/ibuild
    [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi

export IVER=$1
[[ -z $IVER ]] && exit
export IBUILD_SVN_OPTION=$(grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'})
export IBUILD_SVN_SRV=$(grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'})
export ICASE_SVN_SRV=$(grep '^ICASE_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'ICASE_SVN_SRV=' {'print $2'})
    [[ -z $ICASE_SVN_SRV ]] && export ICASE_SVN_SRV=$IBUILD_SVN_SRV
export IVERSION_SVN_SRV=$(grep '^IVERSION_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IVERSION_SVN_SRV=' {'print $2'})
    [[ -z $IVERSION_SVN_SRV ]] && export IVERSION_SVN_SRV=$IBUILD_SVN_SRV
export ISPEC_SVN_SRV=$(grep '^ISPEC_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'ISPEC_SVN_SRV=' {'print $2'})
    [[ -z $ISPEC_SVN_SRV ]] && export ISPEC_SVN_SRV=$IBUILD_SVN_SRV

mkdir -p $TASK_SPACE/tmp/$SEED
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase $TASK_SPACE/tmp/$SEED/icase
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec/ispec $TASK_SPACE/tmp/$SEED/ispec

cd $TASK_SPACE/tmp/$SEED/icase
export BUILD_INFO=$(find | egrep "/r$IVER." | hear -n1)
if [[ $(egrep 'RESULT=FAILED|RESULT=ISSUE' $BUILD_INFO) ]] ; then
    echo "The build hase issue, please change to another version."
    exit
fi


export ITASK_CMD=$(which itask)
[[ -z $ITASK_CMD ]] && export ITASK_CMD=$TASK_SPACE/tmp/$SEED/ispec/itask && echo "Use $TASK_SPACE/tmp/$SEED/ispec/itask"

export IBUILD_TARGET_PRODUCT=$(grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'})
export IBUILD_GRTSRV_MANIFEST_BRANCH=$(grep '^IBUILD_GRTSRV_MANIFEST_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_MANIFEST_BRANCH=' {'print $2'})
export IBUILD_GRTSRV_MANIFEST=$(grep '^IBUILD_GRTSRV_MANIFEST=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_MANIFEST=' {'print $2'} | sed 's/.xml//g')

for SPEC in $(ls $TASK_SPACE/tmp/$SEED/ispec/spec | grep -v itest | grep $IBUILD_GRTSRV_MANIFEST_BRANCH.$IBUILD_GRTSRV_MANIFEST)
do
    cp $SPEC $TASK_SPACE/tmp/$SEED/$SPEC
    echo IVERSION=$IVER >>$TASK_SPACE/tmp/$SEED/$SPEC
    $ITASK_CMD $TASK_SPACE/tmp/$SEED/$SPEC
done



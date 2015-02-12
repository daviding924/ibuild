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
# 150120 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export SEED=$RANDOM
export TODAY=`date +%y%m%d`
export TOWEEK=`date +%yw%V`
export TOYEAR=`date +%Y`
export HOME=/root

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export IBUILD_SVN_SRV=`grep '^IBUILD_SVN_SRV=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_SRV=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`
export IBUILD_FOUNDER_EMAIL=`grep '^IBUILD_FOUNDER_EMAIL=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_FOUNDER_EMAIL=' {'print $2'}`

export ICASE_REV=$1
export ICASE_URL=`svn log -v -r $ICASE_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1`
if [[ ! `echo $ICASE_URL | grep '^/icase/'` ]] ; then
	exit
fi

mkdir -p $TASK_SPACE/tmp.icase.$SEED
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/icase/icase/$TOYEAR/$TOWEEK $TASK_SPACE/tmp.icase.$SEED/icase
svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/ispec $TASK_SPACE/tmp.icase.$SEED/ispec

export BUILD_INFO_NAME=`basename $ICASE_URL | head -n1`
export BUILD_INFO=$TASK_SPACE/tmp.icase.$SEED/icase/$BUILD_INFO_NAME

export RESULT=`grep '^RESULT=' $BUILD_INFO | awk -F'RESULT=' {'print $2'} | head -n1`
export MAKE_STATUS=`grep '^MAKE_STATUS=' $BUILD_INFO | awk -F'MAKE_STATUS=' {'print $2'} | head -n1`
export BUILD_SPEC=`grep spec.build $BUILD_INFO | awk -F'#' {'print $2'} | head -n1`
export EMAIL_PM=`grep '^EMAIL_PM=' $BUILD_INFO | awk -F'EMAIL_PM=' {'print $2'}`
export EMAIL_REL=`grep '^EMAIL_REL=' $BUILD_INFO | awk -F'EMAIL_REL=' {'print $2'}`
export EMAIL_PATCH_OWNER=`grep '^EMAIL_PATCH_OWNER=' $BUILD_INFO | awk -F'EMAIL_PATCH_OWNER=' {'print $2'}`
export BUILD_TIME=`grep '^BUILD_TIME=' $BUILD_INFO | awk -F'BUILD_TIME=' {'print $2'} | head -n1`
export BUILD_TIME_MIN=`echo $BUILD_TIME / 60 | bc`
export START_TIME=`grep '^START_TIME=' $BUILD_INFO | awk -F'START_TIME=' {'print $2'}`
export END_TIME=`grep '^END_TIME=' $BUILD_INFO | awk -F'END_TIME=' {'print $2'}`
export IBUILD_GRTSRV=`grep '^IBUILD_GRTSRV=' $BUILD_INFO | awk -F'IBUILD_GRTSRV=' {'print $2'}`
export IBUILD_GRTSRV_BRANCH=`grep '^IBUILD_GRTSRV_BRANCH=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_BRANCH=' {'print $2'}`
export IBUILD_GRTSRV_URL=`grep '^IBUILD_GRTSRV_URL=' $BUILD_INFO | awk -F'IBUILD_GRTSRV_URL=' {'print $2'}`
export IBUILD_TARGET_BUILD_VARIANT=`grep '^IBUILD_TARGET_BUILD_VARIANT=' $BUILD_INFO | awk -F'IBUILD_TARGET_BUILD_VARIANT=' {'print $2'}`
export IBUILD_TARGET_PRODUCT=`grep '^IBUILD_TARGET_PRODUCT=' $BUILD_INFO | awk -F'IBUILD_TARGET_PRODUCT=' {'print $2'}`
export IBUILD_MODE=`grep '^IBUILD_MODE=' $BUILD_INFO | awk -F'IBUILD_MODE=' {'print $2'}`
export IVER=`grep '^IVER=' $BUILD_INFO | awk -F'IVER=' {'print $2'}`
export ITASK_REV=`grep '^ITASK_REV=' $BUILD_INFO | awk -F'ITASK_REV=' {'print $2'} | tail -n1`
export SLAVE_HOST=`grep '^SLAVE_HOST=' $BUILD_INFO | awk -F'SLAVE_HOST=' {'print $2'}`
export SLAVE_IP=`grep '^SLAVE_IP=' $BUILD_INFO | awk -F'SLAVE_IP=' {'print $2'}`
export DOWNLOAD_URL=`grep '^DOWNLOAD_URL=' $BUILD_INFO | awk -F'DOWNLOAD_URL=' {'print $2'} | head -n1`
export DOWNLOAD_PKG_NAME=`grep '^DOWNLOAD_PKG_NAME=' $BUILD_INFO | awk -F'DOWNLOAD_PKG_NAME=' {'print $2'} | head -n1`

export GERRIT_CHANGE_ID=`grep '^GERRIT_CHANGE_ID=' $BUILD_INFO | awk -F'GERRIT_CHANGE_ID=' {'print $2'}`
export GERRIT_CHANGE_NUMBER=`grep '^GERRIT_CHANGE_NUMBER=' $BUILD_INFO | awk -F'GERRIT_CHANGE_NUMBER=' {'print $2'}`
export GERRIT_CHANGE_OWNER_EMAIL=`grep '^GERRIT_CHANGE_OWNER_EMAIL=' $BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_EMAIL=' {'print $2'}`
if [[ ! -z $GERRIT_CHANGE_OWNER_EMAIL && `grep $GERRIT_CHANGE_OWNER_EMAIL $TASK_SPACE/tmp.icase.$SEED/ispec/conf/mail.conf` ]] ; then
	export OWNER_EMAIL=$GERRIT_CHANGE_OWNER_EMAIL
fi

export GERRIT_CHANGE_OWNER_NAME=`grep '^GERRIT_CHANGE_OWNER_NAME=' $BUILD_INFO | awk -F'GERRIT_CHANGE_OWNER_NAME=' {'print $2'}`
export GERRIT_CHANGE_URL=`grep '^GERRIT_CHANGE_URL=' $BUILD_INFO | awk -F'GERRIT_CHANGE_URL=' {'print $2'}`
export GERRIT_PATCHSET_NUMBER=`grep '^GERRIT_PATCHSET_NUMBER=' $BUILD_INFO | awk -F'GERRIT_PATCHSET_NUMBER=' {'print $2'}`
export GERRIT_PATCHSET_REVISION=`grep '^GERRIT_PATCHSET_REVISION=' $BUILD_INFO | awk -F'GERRIT_PATCHSET_REVISION=' {'print $2'}`
export GERRIT_PROJECT=`grep '^GERRIT_PROJECT=' $BUILD_INFO | awk -F'GERRIT_PROJECT=' {'print $2'}`
if [[ ! -z $GERRIT_PROJECT && `grep $GERRIT_PROJECT $TASK_SPACE/tmp.icase.$SEED/ispec/conf/project.conf` ]] ; then
	export OWNER_EMAIL=$GERRIT_CHANGE_OWNER_EMAIL
fi

export MAIL_LIST=$IBUILD_FOUNDER_EMAIL
if [[ ! -z $EMAIL_TMP && ! `echo $EMAIL_TMP | egrep 'root|ubuntu'` ]] ; then
	export MAIL_LIST="$MAIL_LIST,$EMAIL_TMP"
fi

if [[ ! -z $OWNER_EMAIL && ! -z $MAKE_STATUS ]] ; then
	export MAIL_LIST="$MAIL_LIST,$OWNER_EMAIL"
elif [[ ! -z $MAKE_STATUS || ! -z $DOWNLOAD_PKG_NAME ]] ; then
	[[ ! -z $EMAIL_PM ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_PM"
	[[ ! -z $EMAIL_REL ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_REL"
	[[ ! -z $EMAIL_PATCH_OWNER ]] && export MAIL_LIST="$MAIL_LIST,$EMAIL_PATCH_OWNER"
fi

echo -e "Hi, $GERRIT_CHANGE_OWNER_NAME

After ${BUILD_TIME_MIN}min, node $SLAVE_HOST ($SLAVE_IP) build $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT $RESULT

All of log and packages download URL:
$DOWNLOAD_URL
" >/tmp/$ICASE_REV.mail

[[ ! -z $DOWNLOAD_PKG_NAME ]] && echo -e "wget $DOWNLOAD_URL/$DOWNLOAD_PKG_NAME" >>/tmp/$ICASE_REV.mail
[[ $RESULT != PASSED ]] && echo -e "Error Log:\n$DOWNLOAD_URL/log/error.log" >>/tmp/$ICASE_REV.mail

echo -e "
It based on $IBUILD_GRTSRV/$IBUILD_GRTSRV_URL -b $IBUILD_GRTSRV_BRANCH

Other info:
$BUILD_SPEC" >>/tmp/$ICASE_REV.mail

if [[ ! -z $GERRIT_PATCHSET_REVISION ]] ; then
	echo "GERRIT_CHANGE_ID: $GERRIT_CHANGE_ID" >>/tmp/$ICASE_REV.mail
	echo "repo download $GERRIT_PROJECT $GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER" >>/tmp/$ICASE_REV.mail
fi

if [[ $IBUILD_MODE = bundle ]] ; then
	grep '^BUNDLE_PATCH=' $BUILD_INFO | awk -F'BUNDLE_PATCH=' {'print $2'} | while read BUNDLE_PATCH_ENTRY
	do
		echo "$BUNDLE_PATCH_ENTRY" >>/tmp/$ICASE_REV.mail
	done
	export SUB_IBUILD_MODE="[$IBUILD_MODE]"
fi

echo -e "

-dw
from ibuild system
[Daedalus]
" >>/tmp/$ICASE_REV.mail

[[ ! -z $ITASK_REV ]] && export SUB_ITASK_REV="[$ITASK_REV]"
cat /tmp/$ICASE_REV.mail | mail -s "[ibuild][$RESULT]$SUB_ITASK_REV$SUB_IBUILD_MODE $IBUILD_TARGET_PRODUCT-$IBUILD_TARGET_BUILD_VARIANT in $SLAVE_HOST" $MAIL_LIST

rm -f /tmp/$ICASE_REV.mail
rm -fr $TASK_SPACE/tmp.icase.$SEED

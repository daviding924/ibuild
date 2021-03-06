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
# 150204 Create by Ding Wei
source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export TASK_SPACE=/dev/shm
export SEED=$RANDOM
export TOYEAR=`date +%Y`
export TOWEEK=`date +%yw%V`
[[ `echo $* | grep debug` ]] && export DEBUG=echo || export DEBUG=''
[[ `echo $* | grep stopwatch` ]] && exit

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -e $HOME/ibuild/conf/ibuild.conf ]] ; then
    echo -e "Please put ibuild in your $HOME"
    exit 0
fi

export SVN_SRV_IBUILD=`grep '^SVN_SRV_IBUILD=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'SVN_SRV_IBUILD=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`

export ICHANGE_REV=$1
export WATCH_TMP=tmp/ichange.$ICHANGE_REV
export ISPEC_PATH=$TASK_SPACE/$WATCH_TMP/ispec
export WATCHDOG_PATH=$TASK_SPACE/$WATCH_TMP/ispec/watchdog

mkdir -p $TASK_SPACE/$WATCH_TMP

svn co -q $IBUILD_SVN_OPTION svn://$SVN_SRV_IBUILD/ispec/ispec $TASK_SPACE/$WATCH_TMP/ispec

svn log -v -r $ICHANGE_REV $IBUILD_SVN_OPTION svn://$SVN_SRV_IBUILD/ichange >$TASK_SPACE/$WATCH_TMP/svn.log
export WATCH_GERRIT_SERVER=`cat $TASK_SPACE/$WATCH_TMP/svn.log | grep ichange | egrep -v 'manifest' | awk -F"$TOYEAR" {'print $2'} | awk -F'/' {'print $2'} | sort -u | head -n1`
export WATCH_GERRIT_BRANCH=`cat $TASK_SPACE/$WATCH_TMP/svn.log | grep ichange | egrep -v 'manifest' | grep $TOWEEK | awk -F"$WATCH_GERRIT_SERVER/" {'print $2'} | awk -F"/$TOWEEK.all-change" {'print $1'} | sort -u | head -n1`
if [[ $(cat $TASK_SPACE/$WATCH_TMP/svn.log | egrep '\[topic_build\]') ]] ; then
    export IBUILD_MODE=topic
else
    export IBUILD_MODE=patch
fi

[[ `echo $WATCH_GERRIT_BRANCH | grep all-change` ]] && export WATCH_GERRIT_BRANCH=''

# Code-Review|change-abandoned|change-merged|change-restored|comment-added|merge-failed|patchset-created|reviewer-added|ref-updated
export WATCH_GERRIT_STAGE=`cat $TASK_SPACE/$WATCH_TMP/svn.log | egrep 'change-merged|change-restored|merge-failed|patchset-created' | awk -F"$TOWEEK." {'print $2'}`

export SLEEP=$(expr $(ps aux | grep blame | wc -l) % 10)
sleep $SLEEP
if [[ $(svn log $IBUILD_SVN_OPTION -v -r $ICHANGE_REV svn://$SVN_SRV_IBUILD/ichange/ichange | grep all-change) ]] ; then
    svn blame $IBUILD_SVN_OPTION -r $ICHANGE_REV:$ICHANGE_REV svn://$SVN_SRV_IBUILD/ichange/ichange/$TOYEAR/$WATCH_GERRIT_SERVER/$WATCH_GERRIT_BRANCH/$TOWEEK.all-change >$TASK_SPACE/$WATCH_TMP/svn.blame
fi

if [[ -e $TASK_SPACE/$WATCH_TMP/svn.blame ]] ; then
    export ICHANGE_ENTRY=$(tail -n1 $TASK_SPACE/$WATCH_TMP/svn.blame | awk -F' ' {'print $3'})
    export WATCH_GERRIT_revision=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $1'})
    export WATCH_GERRIT_id=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $2'})
    export WATCH_GERRIT_email=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $3'})
    [[ -z $WATCH_GERRIT_email ]] && export WATCH_GERRIT_email=no_mail
    export WATCH_GERRIT_PATH=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $4'})
    export WATCH_GERRIT_PROJECT=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $5'})
    export WATCH_GERRIT_change_number=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $6'})
    export WATCH_GERRIT_patchSet_number=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $7'})
    export WATCH_GERRIT_value=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $8'})
    export WATCH_GERRIT_REFSPEC=$(echo $ICHANGE_ENTRY | awk -F'|' {'print $9'})
else
    exit
fi

SPEC_EXT()
{
 export SPEC_EXT_URL=$1
 export SPEC_EXT_NAME=$IBUILD_MODE.`basename $SPEC_EXT_URL`

 cat $SPEC_EXT_URL | egrep -v 'IBUILD_MODE=|IBUILD_PRIORITY=' >$TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME
 cat << _EOF_ >>$TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME
GERRIT_CHANGE_NUMBER=$WATCH_GERRIT_change_number
GERRIT_CHANGE_ID=$WATCH_GERRIT_id
GERRIT_CHANGE_URL=$GERRIT_CHANGE_URL
GERRIT_CHANGE_OWNER_EMAIL=$WATCH_GERRIT_email
GERRIT_CHANGE_OWNER_NAME=`echo $WATCH_GERRIT_email | awk -F'@' {'print $1'}`
GERRIT_PATCHSET_NUMBER=$WATCH_GERRIT_patchSet_number
GERRIT_PATCHSET_REVISION=$WATCH_GERRIT_revision
GERRIT_PROJECT=$WATCH_GERRIT_PROJECT
GERRIT_REFSPEC=$WATCH_GERRIT_REFSPEC
IBUILD_MODE=$IBUILD_MODE
IBUILD_PRIORITY=3
_EOF_

 if [[ `echo $WATCH_GERRIT_STAGE | grep 'change-merged'` ]] ; then
    cat $TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME | egrep -v 'GERRIT_CHANGE_NUMBER' >$TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME.tmp
    echo "GERRIT_CHANGE_STATUS=change-merged $WATCH_GERRIT_change_number" >>$TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME.tmp
    cp $TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME.tmp $TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME
 fi

 md5sum $TASK_SPACE/$WATCH_TMP/$SPEC_EXT_NAME
}

ITASK_SUBMIT()
{
 export WATCHDOG_NUM_CONF=`echo $WATCHDOG_CONF | awk -F'.' {'print $1'}`
 export WATCHDOG_SPEC=`echo $WATCHDOG_CONF | awk -F"$WATCHDOG_NUM_CONF" {'print $2'}`
 export ITASK_CMD=$(which itask)
 [[ -z $ITASK_CMD ]] && export ITASK_CMD=$ISPEC_PATH/itask && echo "Use $ISPEC_PATH/itask"

 [[ ! -z $WATCH_GERRIT_PROJECT && $(grep ^$WATCH_GERRIT_PROJECT$ $ISPEC_PATH/conf/ignore.conf) ]] && export WATCH_GERRIT_email=no_mail
 
 sleep `expr $RANDOM % 7 + 1`
 date
 for SPEC_NAME in `ls $ISPEC_PATH/spec | grep $WATCHDOG_SPEC$`
 do
    SPEC_EXT $ISPEC_PATH/spec/$SPEC_NAME
    [[ $WATCH_GERRIT_email != no_mail ]] && $DEBUG $ITASK_CMD $TASK_SPACE/$WATCH_TMP/$IBUILD_MODE.$SPEC_NAME
    $DEBUG mv $TASK_SPACE/$WATCH_TMP/$IBUILD_MODE.$SPEC_NAME $TASK_SPACE/$WATCH_TMP/$IBUILD_MODE.$SPEC_NAME.$RANDOM
 done
 echo $ICHANGE_REV
 echo $ICHANGE_ENTRY 
}

MAIL_MATCHING()
{
 if [[ `grep $WATCH_GERRIT_email $ISPEC_PATH/conf/mail.conf` ]] ; then
    ITASK_SUBMIT
 fi
}

PROJECT_MATCHING()
{
 if [[ `grep $WATCH_GERRIT_PROJECT$ $ISPEC_PATH/conf/project.conf` ]] ; then
    ITASK_SUBMIT
 fi
}

VALUE_MATCHING()
{
 export VALUE_MATCHING_CHK=''
 for VALUE in `echo $WATCH_GERRIT_value | sed 's/,/ /g'`
 do
    if [[ ! `grep "^deny:$VALUE" $ISPEC_PATH/conf/value.conf` ]] ; then
        export VALUE_MATCHING_CHK=yes
    elif [[ `grep "^allow:$VALUE" $ISPEC_PATH/conf/value.conf` ]] ; then
        export VALUE_MATCHING_CHK=yes
    else
        export VALUE_MATCHING_CHK=
    fi
 done
 [[ ! -z $VALUE_MATCHING_CHK ]] && ITASK_SUBMIT
}

ITASK_MATCHING()
{
 export WATCHDOG_GERRIT_PROJECT=`grep 'IF_GERRIT_PROJECT=' $WATCHDOG_CONF | awk -F'IF_GERRIT_PROJECT=' {'print $2'}`
 export WATCHDOG_GERRIT_email=`grep 'IF_email=' $WATCHDOG_CONF | awk -F'IF_email=' {'print $2'}`
 export WATCHDOG_GERRIT_value=`grep 'IF_value=' $WATCHDOG_CONF | awk -F'IF_value=' {'print $2'}`
 export WATCHDOG_GERRIT_CodeReview=`grep 'IF_CodeReview=' $WATCHDOG_CONF | awk -F'IF_CodeReview=' {'print $2'}`
 export WATCHDOG_GERRIT_change_merged=`grep 'IF_change-merged=' $WATCHDOG_CONF | awk -F'IF_change-merged=' {'print $2'}`

 if [[ `grep '=debug$' $WATCHDOG_CONF` ]] ; then
    ITASK_SUBMIT
 elif [[ ! -z $WATCHDOG_GERRIT_PROJECT ]] ; then
    PROJECT_MATCHING
 elif [[ ! -z $WATCHDOG_GERRIT_email ]] ; then
    EMAIL_MATCHING
 elif [[ ! -z $WATCHDOG_GERRIT_CodeReview && ! -z $WATCHDOG_GERRIT_value ]] ; then
    VALUE_MATCHING
 fi
}

cd $WATCHDOG_PATH
touch tmp
for WATCHDOG_CONF in `grep $WATCH_GERRIT_SERVER * | awk -F':' {'print $1'}`
do
    if [[ `grep $WATCH_GERRIT_BRANCH $WATCHDOG_CONF` ]] ; then
        export WATCHDOG_GERRIT_STAGE=`grep $WATCH_GERRIT_STAGE $WATCHDOG_CONF | awk -F"IF_$WATCH_GERRIT_STAGE=" {'print $2'}`
        [[ ! -z $WATCHDOG_GERRIT_STAGE ]] && ITASK_MATCHING
    fi
done

rm -f $WATCHDOG_PATH/tmp
[[ -z $DEBUG ]] && rm -fr $TASK_SPACE/tmp/ichange.$ICHANGE_REV



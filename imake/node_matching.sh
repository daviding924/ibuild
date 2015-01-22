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
# 150122 Create by Ding Wei
[[ -f /tmp/EXIT ]] && exit

source /etc/bash.bashrc
export LC_CTYPE=C
export LC_ALL=C
export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -f $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

source $IBUILD_ROOT/imake/function
EXPORT_IBUILD_CONF

EXIT()
{
 rm -f $TASK_SPACE/itask-r$ITASK_REV.lock
 rm -f $TASK_SPACE/itask-r$ITASK_REV.jobs
 rm -f $TASK_SPACE/itask.lock
 rm -f /tmp/ihook-r$ITASK_REV.log
 exit
}

MATCHING()
{
 export LEVEL_NUMBER=$1
 echo $ITASK_PATH >$TASK_SPACE/itask.lock
 touch $TASK_SPACE/node.load
 
 if [[ ! -d $TASK_SPACE/inode.lock ]] ; then
	svn co -q $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask/inode $TASK_SPACE/inode.lock
 fi

 export NODE_TOTAL=`cat $IBUILD_ROOT/conf/priority/level-[$LEVEL_NUMBER].conf | sort -u | wc -l`
 export NODE_LOAD=`cat $TASK_SPACE/node.load | sort -u | wc -l`

 if [[ $NODE_TOTAL = $NODE_LOAD ]] ; then
	svn up -q $IBUILD_SVN_OPTION $TASK_SPACE/inode.lock
	rm -f $TASK_SPACE/node.load
 fi 

 for NODE in `cat $IBUILD_ROOT/conf/priority/level-[$LEVEL_NUMBER].conf`
 do
	if [[ -f $TASK_SPACE/inode.lock/$NODE ]] ; then
		export NODE_IP=`grep '^IP=' $TASK_SPACE/inode.lock/$NODE | awk -F'IP=' {'print $2'}` 
		export NODE_MD5=`echo $NODE | md5sum | awk -F' ' {'print $1'}`

		echo $ITASK_REV | $NETCAT $NODE_IP 1234
		sleep 1

		$NETCAT $NODE_IP 4321 >$TASK_SPACE/itask-r$ITASK_REV.jobs
		ASSIGN_JOB
	fi
 done
}

ASSIGN_JOB()
{
 if [[ `cat $TASK_SPACE/itask-r$ITASK_REV.jobs | grep $ITASK_REV_MD5 | grep $NODE_MD5` ]] ; then
	echo "$ITASK_REV|$NODE|$NODE_IP|$ITASK_REV_MD5|$NODE_MD5" >>$ITASK_PATH/jobs.txt
	svn ci -q $IBUILD_SVN_OPTION -m "auto: assign itask-r$ITASK_REV to $NODE" $ITASK_PATH/jobs.txt
	rm -f $TASK_SPACE/queue/$ITASK_REV
 fi
 rm -f $TASK_SPACE/inode.lock/$NODE
 echo $NODE >>$TASK_SPACE/node.load
 EXIT
}

export ITASK_QUEUE=$1

for ITASK_REV in `ls $ITASK_QUEUE`
do
	export ITASK_PATH=`ls -d $TASK_SPACE/itask-* | head -n1`
	export ITASK_REV_MD5=`echo $ITASK_REV | md5sum | awk -F' ' {'print $1'}`
	export ITASK_SPEC_URL=`svn log -v -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/itask | egrep 'A |M ' | awk -F' ' {'print $2'} | head -n1`

	if [[ ! `echo $ITASK_SPEC_URL | grep '^/itask/tasks'` ]] ; then
		rm -f $ITASK_QUEUE/$ITASK_REV
	else
		svn export -r $ITASK_REV $IBUILD_SVN_OPTION svn://$IBUILD_SVN_SRV/itask/$ITASK_SPEC_URL $TASK_SPACE/itask-r$ITASK_REV.lock
		export IBUILD_PRIORITY=`grep '^IBUILD_PRIORITY=' $TASK_SPACE/itask-r$ITASK_REV.lock | awk -F'IBUILD_PRIORITY=' {'print $2'}`

		if [[ -z $IBUILD_PRIORITY ]] ; then
			export LEVEL_NUMBER=1-9
		else
			export LEVEL_NUMBER=$IBUILD_PRIORITY
		fi

		MATCHING $LEVEL_NUMBER
	fi
done



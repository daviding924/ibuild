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
export USER=$(whoami)
export TOHOUR=$(date +%H)
export LOCK_SPACE=/dev/shm/lock
mkdir -p $LOCK_SPACE >/dev/null 2>&1

echo $TOHOUR >$LOCK_SPACE/repo_sync.lock

export IBUILD_ROOT=$HOME/ibuild
        [[ -z $IBUILD_ROOT ]] && export IBUILD_ROOT=`dirname $0 | awk -F'/ibuild' {'print $1'}`'/ibuild'
if [[ ! -e $HOME/ibuild/conf/ibuild.conf ]] ; then
	echo -e "Please put ibuild in your $HOME"
	exit 0
fi

export SVN_SRV_IBUILD=`grep '^SVN_SRV_IBUILD=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'SVN_SRV_IBUILD=' {'print $2'}`
export IBUILD_SVN_OPTION=`grep '^IBUILD_SVN_OPTION=' $IBUILD_ROOT/conf/ibuild.conf | awk -F'IBUILD_SVN_OPTION=' {'print $2'}`

mkdir -p ~/.ssh
cd ~/.ssh
if [[ ! -e id_rsa-irobot ]] ; then
	scp $SVN_SRV_IBUILD:.ssh/* .
fi
[[ ! -e ~/.gitconfig ]] && ln -sf ~/.ssh/gitconfig ~/.gitconfig

chown $USER -R /local/workspace
sudo mkdir -p /mnt/tmp
sudo chown $USER /mnt/tmp
sshfs irobot@$SVN_SRV_IBUILD:/local /mnt/tmp 

rm -f $IBUILD_ROOT/bin/repo
time rsync -av /mnt/tmp/workspace/. /local/workspace/ >>/tmp/sync.log

sudo umount /mnt/tmp
sudo reboot


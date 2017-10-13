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
# 171012: Ding Wei created it
export LC_ALL=C
export LC_CTYPE=C
export TODAY=$(date +%y%m%d)
export LOCK_SPACE=/dev/shm/lock
export HOSTNAME_A=$(hostname -A)
export PWD=$(pwd)
[[ ! -d $PWD/conf ]] && exit 1
[[ $(whoami) != root ]] && exit 1

export HOST_TOKEN=$(find /globe/*/token | egrep 'token/key' | awk -F'/' {'print $3'})
[[ ! -e /globe/$HOST_TOKEN/srv/svn/dump ]] && mkdir -p /globe/$HOST_TOKEN/srv/svn/dump

for SVN_REPO in $(ls /globe/$HOST_TOKEN/srv/svn/repo/*)
do
    export SVN_REPO_REV=$(svnadmin deltify /globe/$HOST_TOKEN/srv/svn/repo/$SVN_REPO | awk -F' ' {'print $3'} | awk -F'.' {'print $1'})
    echo $SVN_REPO_REV >/globe/$HOST_TOKEN/srv/svn/dump/$SVN_REPO.rev
    svnadmin dump /globe/$HOST_TOKEN/srv/svn/repo/$SVN_REPO -r$SVN_REPO_REV >/globe/$HOST_TOKEN/srv/svn/dump/$SVN_REPO.dump
done



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
# 150119: Ding Wei created it
# post-commit
export IHOOK_REPOS="$1"
export IHOOK_REV="$2"
export IHOOK_TXN_NAME="$3"

export LC_CTYPE=C
[[ ! -e $HOME/ibuild ]] && export HOME=/local
export IBUILD_ROOT=$HOME/ibuild
source /etc/bash.bashrc
export TODAY=$(date +%y%m%d)

# echo --------------------------------------- >>/tmp/ihook-ichange.log
# echo $IHOOK_REPOS $IHOOK_REV `date` >>/tmp/ihook-ichange.log
[[ -e /tmp/debug-$TODAY ]] && export STOP_WATCH=stopwatch

$IBUILD_ROOT/ihook/watch.sh $IHOOK_REV $STOP_WATCH >>/tmp/watch-$(date +%y%m%d).log 2>&1 &


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
# 150120 created by Ding Wei

hostname
echo --------------------------
ccache -s | egrep -v 'files|unsupported|called|local'
echo --------------------------
sudo umount /run/user/112/gvfs >/dev/null 2>&1
df | grep local
echo --------------------------
sensors | grep ' C ' | egrep 'Physical|temp1'



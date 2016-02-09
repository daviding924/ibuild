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
# 151217 Create by Ding Wei

export REPO_PATH=$1
export GIT_PATH=$2
export NOW=$(date +%y%m%d%H%M%S)
export LOC_WS=$(dirname $GIT_PATH)

[[ ! -d $REPO_PATH/.repo || ! -d $GIT_PATH/.git ]] && exit 1


mkdir -p $LOC_WS/$NOW

cd $REPO_PATH
repo manifest -r -o manifest-$(date +%y%m%d).xml

mv $REPO_PATH/.repo $LOC_WS/$NOW/repo
mv $GIT_PATH/.git $LOC_WS/$NOW/git
[[ -d $REPO_PATH/out ]] && mv $REPO_PATH/out $LOC_WS/$NOW/out.repo
rm -f $GIT_PATH/manifest*.xml

find | awk -F'^./' {'print $2'} >$LOC_WS/$NOW/file_repo.list

echo "tail -f /tmp/repo2git.log"
rsync -av --delete $REPO_PATH/ $GIT_PATH/ >/tmp/repo2git.log 2>&1

cd $GIT_PATH
for CLEAN in `cat $LOC_WS/$NOW/file_repo.list | egrep '.git$|.gitignore$|.svn$|.gitattributes$'`
do
    rm -fr $GIT_PATH/$CLEAN
done

for CLEAN in `cat $LOC_WS/$NOW/file_repo.list | egrep 'darwin-x86' | grep prebuilts`
do
    rm -fr $GIT_PATH/$CLEAN
done

rm -f $GIT_PATH/prebuilts/misc/linux-x86/ccache/*
cp /usr/bin/ccache $GIT_PATH/prebuilts/misc/linux-x86/ccache/

rm -fr cts docs

mv $LOC_WS/$NOW/git $GIT_PATH/.git

git status >$LOC_WS/$NOW/git.status 2>&1

for GIT_ADD in `cat $LOC_WS/$NOW/git.status | grep '^#' | egrep 'deleted|modified' | awk -F' ' {'print $3'} | awk -F'/' {'print $1'} | sort -u`
do
    echo '------------------------------'
    echo process $GIT_ADD
    echo '------------------------------'
    git add $GIT_ADD
    git commit -m "auto commit $GIT_ADD" $GIT_ADD
    git push
done

for GIT_IGNORE in `cat $LOC_WS/$NOW/file_repo.list | egrep '.git$|.gitignore$|.gitattributes$'`
do
    export GIT_IGNORE_PATH=`dirname $GIT_IGNORE`
    [[ -d $GIT_IGNORE ]] && cp $GIT_PATH/$GIT_IGNORE $REPO_PATH/$GIT_IGNORE
done

git add *
git commit -m "auto commit gitignore" *
git push

mv $LOC_WS/$NOW/repo $REPO_PATH/.repo
mv $LOC_WS/$NOW/out.repo $REPO_PATH/out



imake tools
======

#### add_task.sh
stand-alone tool, add ibuild task as a job in svn:itask
Usage: add_task.sh spec.build_file

#### build.sh
stand-alone tool, build from spec.build file which link in /dev/shm/spec.build or itask job revision

Usage: build.sh [svn:itask job rversion]

#### clean_btrfs.sh
stand-alone tool, clean btrfs disk mount point from /local/workspace

#### timer_build.sh
stand-alone tool, daily bundle 24h patches build from svn:ispec/ispec/timer define, add ibuild task as a job in svn:itask

#### function
non-stand-alone tool, function for imake

#### make_5.sh
non-stand-alone tool, build steps, which define in svn:ispec/ispec/spec/spec.build files


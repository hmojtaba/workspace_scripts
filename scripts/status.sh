#!/bin/bash

source $ROSWSS_ROOT/setup.bash ""
source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

function getSpecBranch()
{
  local entry
  entry=$1

  local desiredBranch
  desiredBranch=$(wstool info $entry | grep "Spec-Version")
  desiredBranch="${desiredBranch[@]}"
  desiredBranch=${desiredBranch#*: }
  echo $desiredBranch
}

function displayStatus()
{
  local old_d
  old_d=`pwd`
  local dir
  dir=$1
  local desiredBranch
  desiredBranch=$2

  cd $dir
  if [ -z "$desiredBranch" ]
  then
    desiredBranch=$(git log --pretty='%d' -1 HEAD | perl -ne 'm#(?<=origin/)([^,]*)# && print "$1\n"')
  fi

  if [ -e "$dir/.git" ]
  then
    if [ "$(git rev-parse --abbrev-ref HEAD)" != "$desiredBranch" ] \
       || [ -n "$(git status --porcelain)" ] \
       || [ -n "$(git status | grep -P 'branch is (ahead|behind)')" ]
    then
      echo_note "$PWD:"
      if [ "$(git rev-parse --abbrev-ref HEAD)" != "$desiredBranch" ]
      then
        git status | grep "On branch" | perl -pe "chomp"
        echo_warn " (should be on branch $desiredBranch)"
      fi
      git status | grep -P 'branch is (ahead|behind)'
      echo -ne $RED; git status | grep "modified"; echo -ne $NOCOLOR
      echo -ne $GREEN; git status | grep "new file"; echo -ne $NOCOLOR
      echo -ne $ORANGE; git status | grep "deleted"; echo -ne $NOCOLOR
      if [ -n "$(git status | grep 'Untracked files')" ]
      then
        echo -ne $DGRAY
        git status --porcelain | grep '??' | sed -r 's/^.{3}//' \
        | xargs -I file echo -e '\tuntracked:  '"file"
        echo -ne $NOCOLOR
      fi
      echo
    fi
  elif [ -e "$dir/.hg" ]; then
    if [ "$(hg branch)" != "$desiredBranch" ] \
       || [ -n "$(hg status)" ]
    then
      echo "$PWD:"
      echo "On hg branch `hg branch`"
      hg status
      hg incoming | grep "changes"
      echo
    fi
  #else
    #echo "$PWD is not a repository!"
    #echo
  fi
  cd $old_d
}

cd ${ROSWSS_ROOT}
echo_info "Looking for changes in $PWD ..."
displayStatus $PWD

if [ -d $ROSWSS_ROOT/rosinstall/optional/custom/.git ]; then
    cd $ROSWSS_ROOT/rosinstall/optional/custom
    echo_info "Looking for changes in $PWD ..."
    displayStatus $PWD
fi

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -d $dir/custom/.git ]; then
        cd $dir/custom
        echo_info "Looking for changes in $PWD ..."
        displayStatus $PWD
    fi
done

echo_info "Looking for changes in ${ROS_WORKSPACE} ..."
roscd
entries=$(wstool foreach echo)
for e in ${entries[@]};
do
  e=${e#*[}
  e=${e%]*}
  branch=$(getSpecBranch $e)
  displayStatus $ROSWSS_ROOT/$e $branch
done

echo_info "Status check done!"


#!/bin/bash
export ROSWSS_REMOTE_PC_SCRIPTS=()
export ROSWSS_SEP_SYM=';'

# Define variables with default values. See 20.setup... for a template / documentation
export ROSWSS_PREFIX="roswss"
export ROSWSS_INSTALL_DIR="rosinstall"


# export important variables (do not change!)
export HOSTNAME=$(hostname)

if [ -z $ROS_WORKSPACE ]; then
  if [ ! -z $CMAKE_PREFIX_PATH ]; then
    IFS=":" read -a _roswss_workspaces <<< "$CMAKE_PREFIX_PATH"
    for _roswss_ws in "${_roswss_workspaces[@@]}"
    do
      if [ -f $_roswss_ws/.catkin ]; then
        export ROS_WORKSPACE=$(cd ${_roswss_ws}/..; pwd)/src
        break
      fi
    done
  fi
  if [ -z $ROS_WORKSPACE ]; then
    echo -e "Neither ROS_WORKSPACE is set nor a catkin workspace is listed in CMAKE_PREFIX_PATH.  Please set ROS_WORKSPACE or source a catkin workspace to use the TUDa workspace scripts."
  fi
fi
export ROSWSS_ROOT=$(cd $ROS_WORKSPACE/..; pwd)
export ROSWSS_LOG_DIR="${ROSWSS_ROOT}/logs"

# Use this method to register different remote pcs
# Syntax:
#   add_remote_pc <script_name> <host_name> <screen_name> <command>
# Example:
#   add_remote_pc "motion" "thor-motion" "motion" "roslaunch thor_mang_onboard_launch motion.launch"
function add_remote_pc() {
    script_name="$1"
    export ${script_name}_remote_pc="${1}${ROSWSS_SEP_SYM}${2}${ROSWSS_SEP_SYM}${3}${ROSWSS_SEP_SYM}${4}"
    ROSWSS_REMOTE_PC_SCRIPTS+=($script_name)
}



export ROSWSS_COMPLETION_TAGS=()
export ROSWSS_COMPLETION_SCRIPTS=()

# Use this method to register additional auto completion scripts
# Example:
#   add_completion "my_command" "completion_function"
function add_completion()
{
  ROSWSS_COMPLETION_TAGS+=($1)
  ROSWSS_COMPLETION_SCRIPTS+=($2)
}



# export default scripts folder
unset ROSWSS_SCRIPTS

@[if DEVELSPACE]@
export ROSWSS_BASE_SCRIPTS="@(PROJECT_SOURCE_DIR)/scripts"
export ROSWSS_SCRIPTS="@(PROJECT_SOURCE_DIR)/scripts:$ROSWSS_SCRIPTS"
@[else]@
export ROSWSS_BASE_SCRIPTS="@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts"
export ROSWSS_SCRIPTS="@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts:$ROSWSS_SCRIPTS"
@[end if]@

# export additional ROS_PACKAGE_PATH for indigo
if [ "$ROS_DISTRO" = "indigo" ]; then
    export ROS_BOOST_LIB_DIR_NAME=/usr/lib/x86_64-linux-gnu
    export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$ROSWSS_ROOT/external
fi

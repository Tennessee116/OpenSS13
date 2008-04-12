#!/bin/sh
#
# This script defines the configuration of the Automated Build server.

export LOCAL_SOURCE_PATH="/usr/local/byond/automated-build-server/src"
export LOG_MAX_AGE="10"
export REMOTE_SOURCE_PATH="https://openss13.svn.sourceforge.net/svnroot/openss13/trunk/main-src"
export SCRIPTS_PATH="/usr/local/byond/automated-build-server/bin"
export SERVER_PATH="/usr/local/byond/automated-build-server/server"
export SERVER_PORT="10000"
export SERVER_OPTIONS="-safe -logself"

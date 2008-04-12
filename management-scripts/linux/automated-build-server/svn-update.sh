#!/bin/sh
#
# This script does the svn update, if necessary rebuilding and reloading the server.

source configuration.sh

cd $LOCAL_SOURCE_PATH
REMOTE_VERSION=`svn info $REMOTE_SOURCE_PATH | grep 'Revision:' | gawk '{print $2}'`
LOCAL_VERSION=`svn info . | grep 'Revision:' | gawk '{print $2}'`
if [ $REMOTE_VERSION -gt $LOCAL_VERSION ]; then
	svn update
	$SCRIPTS_PATH/build-version.sh
fi

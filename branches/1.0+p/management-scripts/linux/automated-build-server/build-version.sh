#!/bin/sh
#
# This script is responsible for doing the SVN update, priming the source code and
# actually building the Automated version.

source configuration.sh

cd $LOCAL_SOURCE_PATH
sed -i -e 's/SS13_version = ".*"/SS13_version = "Automated Build Server"/' Code/globals.dm
DreamMaker spacestation13.dme
if [ $? -ne 0 ]; then
	svn revert Code/globals.dm
fi
svn revert Code/globals.dm
mv -f spacestation13.dmb $SERVER_PATH/spacestation13.dmb~
mv -f spacestation13.rsc $SERVER_PATH/spacestation13.rsc~
$SCRIPTS_PATH/load-version.sh

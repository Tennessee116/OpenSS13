#/!bin/sh
#
# This script is responsible for loading, or switching the servers.

source configuration.sh

cd $SERVER_PATH
if [ -f ./process.pid ]; then
	PID=`cat ./process.pid`
	kill $PID
	rm -f ./process.pid
fi
$SCRIPTS_PATH/rotate-logs.sh
if [ -e spacestation13.dmb~ ]; then
	mv -f spacestation13.dmb~ spacestation13.dmb
fi
if [ -e spacestation13.rsc~ ]; then
	mv -f spacestation13.rsc~ spacestation13.rsc
fi

DreamDaemon spacestation13.dmb $SERVER_PORT $SERVER_OPTIONS &
echo $! > process.pid

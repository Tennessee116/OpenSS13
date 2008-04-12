#/!bin/sh
#
# This script rotates the logs.

source configuration.sh

cd $SERVER_PATH
if [ -e spacestation13.$LOG_MAX_AGE.log ]; then
	rm -f spacestation.$LOG_MAX_AGE.log
fi

N=`expr $LOG_MAX_AGE - 1`
while [ $N -gt 0 ]; do
	if [ -e spacestation13.$N.log ]; then
		mv -f spacestation.$N.log spacestation.`expr $N + 1`.log
	fi
	N=`expr $N - 1`
done

if [ -e spacestation13.log ]; then
	mv -f spacestation13.log spacestation13.1.log
fi

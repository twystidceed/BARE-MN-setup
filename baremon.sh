#!/bin/bash
# baremon 1.0 - BARE Masternode Monitoring 
NAME=bare
SCRIPT=baremon.sh
HIDDEN=.bare
TICKER=BARE
#Processing command line params
if [ -z $1 ]; then dly=1; else dly=$1; fi   # Default refresh time is 1 sec

datadir="/$USER/$HIDDEN$2"   # Default datadir is /root/$HIDDEN
 
# Install jq if it's not present
dpkg -s jq 2>/dev/null >/dev/null || sudo apt-get -y install jq

#It is a one-liner script for now
watch -ptn $dly "echo '===========================================================================
Outbound connections to other $TICKER nodes [$TICKER datadir: $datadir]
===========================================================================
Node IP               Ping    Rx/Tx     Since  Hdrs   Height  Time   Ban
Address               (ms)   (KBytes)   Block  Syncd  Blocks  (min)  Score
==========================================================================='
$NAME-cli -datadir=$datadir getpeerinfo | jq -r '.[] | select(.inbound==false) | \"\(.addr),\(.pingtime*1000|floor) ,\
\(.bytesrecv/1024|floor)/\(.bytessent/1024|floor),\(.startingheight) ,\(.synced_headers) ,\(.synced_blocks)  ,\
\((now-.conntime)/60|floor) ,\(.banscore)\"' | column -t -s ',' && 
echo '==========================================================================='
uptime
echo '==========================================================================='
echo 'Masternode Status: \n# $NAME-cli masternode status' && $NAME-cli -datadir=$datadir masternode status
echo '==========================================================================='
echo 'Sync Status: \n# $NAME-cli mnsync status' &&  $NAME-cli -datadir=$datadir mnsync status
echo '==========================================================================='
echo 'Masternode Information: \n# $NAME-cli getinfo' && $NAME-cli -datadir=$datadir getinfo
echo '==========================================================================='
echo 'Usage: $SCRIPT [refresh delay] [datadir index]'
echo 'Example: $SCRIPT 10 22 will run every 10 seconds and query domod in /$USER/$HIDDEN22'
echo '\n\nPress Ctrl-C to Exit...'"

#!/bin/bash

die() { echo "$@" 1>&2; exit 1; }

[ $# -eq 4 ] || die "4 hostname parameters missing - exiting"

HOST=$1
HOSTS[0]=$2
HOSTS[1]=$3
HOSTS[2]=$4

echo "=============="
echo "-- Setting '$HOST' to be Primary --"

echo "--- killing mongod processes ---"
ssh -t ${HOSTS[0]} "sudo service mongod stop; sleep 1; sudo killall mongod"
ssh -t ${HOSTS[1]} "sudo service mongod stop; sleep 1; sudo killall mongod"
ssh -t ${HOSTS[2]} "sudo service mongod stop; sleep 1; sudo killall mongod"
echo "--- nuking /data directory ---"
ssh -t ${HOSTS[0]} "sudo rm -rf /data/*"
ssh -t ${HOSTS[1]} "sudo rm -rf /data/*"
ssh -t ${HOSTS[2]} "sudo rm -rf /data/*"
sleep 2
echo "--- starting mongod processes ---"
ssh -t ${HOSTS[0]} "sudo service mongod start"
ssh -t ${HOSTS[1]} "sudo service mongod start"
ssh -t ${HOSTS[2]} "sudo service mongod start"

sleep 5

echo "--- setting up new replica set config ---"
m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.initiate())"

# wait for at most 5 minutes (60 * 10 = 600 seconds)
for i in {0..60}; do
	echo -n .
	sleep 10
	ismaster=`m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.isMaster().ismaster)"`
	if [ "$ismaster" == "true" ]; then
		echo
		break
	fi
done

if [ "$ismaster" != "true" ]; then
	echo
	exit 1
fi

[ "$HOST" != "${HOSTS[0]}" ] && m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.add('${HOSTS[0]}'))"
[ "$HOST" != "${HOSTS[1]}" ] && m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.add('${HOSTS[1]}'))"
[ "$HOST" != "${HOSTS[2]}" ] && m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.add('${HOSTS[2]}'))"

sleep 10

echo "-- New config from '$HOST' --"
m shell 2.6.3 $HOST/ycsb --quiet --eval "printjson(rs.status().members)"

echo "-- Done --"

#!/bin/bash

die() { echo "$@" 1>&2; exit 1; }

echo "=============="

[ "$HOST" != "" ] || die "No HOST specified - exiting"
[ "$PRIMARYID" != "" ] || die "No PRIMARYID specified - exiting"

echo "-- Stepping up '$HOST' to be Primary --"

PRIMARY=`m shell 2.6.3 $HOST/ycsb --quiet --eval "rs.isMaster().primary"`

echo "-- Current Primary: '$PRIMARY' --"

echo "-- Dropping database before switching... --"
m shell 2.6.3 ${PRIMARY}/ycsb --quiet --eval "printjson(db.dropDatabase())"

echo "-- Setting '$HOST' to be the Primary --"

# see https://github.com/micha/jsawk/issues/25 if jsawk fails here...
NEWCONF=`m shell 2.6.3 $HOST/ycsb --quiet --eval "printjsononeline(rs.conf())" | jsawk -v PRIMARYID=$PRIMARYID 'forEach(this.members, "if (this._id==PRIMARYID) this.priority=1; else this.priority=0.5")'`

m shell 2.6.3 $PRIMARY/ycsb --quiet --eval "printjson(rs.reconfig($NEWCONF))"

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

echo "-- New config from '$HOST' --"
m shell 2.6.3 $HOST/ycsb --quiet --eval "printjsononeline(rs.conf())"

echo "-- Done with stepup --"

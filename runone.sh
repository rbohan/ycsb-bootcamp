#!/bin/bash

die() { echo "$@" 1>&2; exit 1; }

[ "$HOST" != "" ]        || die "No HOST specified - exiting"
[ "$WORKLOAD" != "" ]    || die "No WORKLOAD specified - exiting"
[ "$PHASE" != "" ]       || die "No PHASE specified - exiting"
[ "$THREADS" != "" ]     || die "No THREADS specified - exiting"
[ "$RECORDCOUNT" != "" ] || die "No RECORDCOUNT specified - exiting"
[ "$OPCOUNT" != "" ]     || die "No OPCOUNT specified - exiting"
[ "$BULK" != "" ]        || die "No BULK specified - exiting"

echo "================="
echo "Starting new run (" $(date '+%d/%m/%y %H:%M:%S') ")"
echo "Host: $HOST, Workload: $WORKLOAD -- $PHASE ($THREADS threads)"
echo "================="

function cleanup() {
	echo "-- Cleaning up..."
	kill $ioStatsTailPID
	ssh $HOST "killall iostats.sh"
	kill $ioStatsPID
	kill $topStatsTailPID
	ssh $HOST "killall topstats.sh"
	kill $topStatsPID
	kill $mongoStatsTailPID
	kill $mongoStatsPID

	wait >& /dev/null

	# add blank lines to avoid partially written output
	echo >> mongostats.out
	echo >> topstats.out
	echo >> iostats.out
}
trap cleanup EXIT SIGHUP SIGINT SIGTERM

DATE=`date`

echo $DATE > data/mongostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out
python -u ./mongostats.py -n $HOST -w $WORKLOAD -p $PHASE -t $THREADS >> data/mongostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out &
mongoStatsPID=$!
tail -n +2 -f data/mongostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out >> mongostats.out &
mongoStatsTailPID=$!

echo $DATE > data/topstats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out
scp ./topstats.sh $HOST:.
ssh $HOST "./topstats.sh" >> data/topstats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out &
topStatsPID=$!
tail -n +2 -f data/topstats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out >> topstats.out &
topStatsTailPID=$!

echo $DATE > data/iostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out
scp ./iostats.sh $HOST:.
ssh $HOST "./iostats.sh" >> data/iostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out &
ioStatsPID=$!
tail -n +2 -f data/iostats.$HOST.$WORKLOAD.$PHASE.t$THREADS.out >> iostats.out &
ioStatsTailPID=$!

sleep 5

echo $DATE > data/ycsb.$HOST.$WORKLOAD.$PHASE.t$THREADS.out
ssh ycsb-client "cd YCSB; ./bin/ycsb $PHASE mongodb -P workloads/${WORKLOAD} -threads ${THREADS} -p mongodb.url=mongodb://${HOST}:27017 -p recordcount=${RECORDCOUNT} -p operationcount=${OPCOUNT} -p measurementtype=timeseries ${EXTRA_OPTS} -bulk ${BULK}" >> data/ycsb.$HOST.$WORKLOAD.$PHASE.t$THREADS.out

sleep 5

echo "================="
echo "Done."
echo "================="

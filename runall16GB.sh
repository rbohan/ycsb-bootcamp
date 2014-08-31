#!/bin/bash

export RECORDCOUNT=8000000 # 16GB data (8m * 2kb avg size)
export OPCOUNT=1000000
export BULK=10000

# workload1 = 50:50
# workload2 = 95:05
# workload3 = 100:0

# hostnames for our 3 hosts
HOSTS[0]=crypto1
HOSTS[1]=crypto2
HOSTS[2]=crypto3

mkdir -p data

echo "=== Starting '$0' @ `date`"

# loop over each host so we can test it as Primary
for i in {0..2}
do
	export HOST=${HOSTS[$i]}

	./reconfig.sh ${HOST} ${HOSTS[0]} ${HOSTS[1]} ${HOSTS[2]}
	if [ $? -ne 0 ]; then echo "Failed to make node '$HOST' the primary - exiting tests"; exit 1; fi

	WORKLOAD=workload1 PHASE=load THREADS=8 ./runone.sh

	for t in {2..7}   # THREADS = 2^i
	do
		export THREADS=$(awk "BEGIN{print 2 ** $t}")
	
		sleep 20
		WORKLOAD=workload1 PHASE=run ./runone.sh
		sleep 20
		WORKLOAD=workload2 PHASE=run ./runone.sh
		sleep 20
		WORKLOAD=workload3 PHASE=run ./runone.sh
	done
done

echo "=== Done @ `date`"

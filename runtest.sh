#!/bin/bash

export RECORDCOUNT=100000
export OPCOUNT=100000
export BULK=10000

# workload1 = 50:50
# workload2 = 95:05
# workload3 = 100:0

# hostnames for our 3 hosts
HOSTS[0]=crypto1
HOSTS[1]=crypto2
HOSTS[2]=crypto3

mkdir -p data

# loop over each host so we can test it as Primary
for i in {0..2}
do
	export HOST=${HOSTS[$i]}

	./reconfig.sh ${HOST} ${HOSTS[0]} ${HOSTS[1]} ${HOSTS[2]}
	if [ $? -ne 0 ]; then echo "Failed to make node '$HOST' the primary - exiting tests"; exit 1; fi

	export THREADS=1

	WORKLOAD=workload1 PHASE=load ./runone.sh
	#WORKLOAD=workload1 PHASE=run ./runone.sh
	#WORKLOAD=workload2 PHASE=run ./runone.sh
	#WORKLOAD=workload3 PHASE=run ./runone.sh

done

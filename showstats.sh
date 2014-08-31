#!/bin/bash

function stats() {
  for workload in {1..3}; do
    echo threads, -, , , Raw ext4, , -, , , Vormetric, , -, , , LUKS
    for t in {0..7}; do
      thread=$(awk "BEGIN{print 2 ** $t}")
      echo -n $thread,
      for host in {1..3}; do
        file=ycsb.crypto${host}.workload${workload}.$1.t$thread.out
        if [ -e ${file} ]; then
          echo -n ${file}, $(grep $2 ${file}), ,
        else
          echo -n ${file}, , , , ,
        fi
      done
      echo
    done
  done
  echo
}

stats load Throughput
stats run Throughput
echo
#stats load RunTime
#stats run RunTime
#echo
#stats load Latency
#stats run Latency

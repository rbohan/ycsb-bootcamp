#!/bin/bash

hostname=$(hostname -s)

# IOSTAT
lineCount=$(iostat | wc -l)
numDevices=$(expr $lineCount - 7);

iostat -x -t 1 |
awk -v numDevices=$numDevices -v hostname=$hostname '
NF==2{
        s=$0
        getline; getline; $1=$1
        print s " CPU " hostname " " $0
}
/Device:/{
        for (i = 0; i < numDevices; i++) {
                getline; $1=$1
                print s " DEVICE " hostname " " $0
        }
}'

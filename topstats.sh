#!/bin/bash

hostname=$(hostname -s)

while(sleep 1); do

# CPU
DATE=$(date '+%d/%m/%y %H:%M:%S')
top -b -n 1 |
awk -v "date=$DATE" -v hostname=$hostname '
BEGIN {
        mongod=0
        secfs=0
        kcryptd=0
}
/mongod/{
        $1=$1
        print date " PROCESS-mongod " hostname " " $0
        mongod+=$9
}
/secfs/{
	# this is also a vormetric process!
        $1=$1
        print date " PROCESS-secfs " hostname " " $0
        secfs+=$9
}
/vmd/{
	# this is also a vormetric process!
        $1=$1
        print date " PROCESS-vmd " hostname " " $0
        secfs+=$9
}
/kcryptd/{
        $1=$1
        print date " PROCESS-kcryptd " hostname " " $0
        kcryptd+=$9
}
END {
        if (mongod > 0) print date " PROCESS-mongod-cpu " hostname " " mongod
        if (secfs > 0) print date " PROCESS-secfs-cpu " hostname " " secfs
        if (kcryptd > 0) print date " PROCESS-kcryptd-cpu " hostname " " kcryptd
}'

done

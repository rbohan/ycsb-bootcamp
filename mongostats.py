#!/usr/bin/python

import sys,argparse,subprocess,time,datetime

def printVals(args, vals):
   insert = int(vals[0])
   query = int(vals[1])
   update = int(vals[2])
   delete = int(vals[3])
   getmore = int(vals[4])
   command = int(vals[5])
   faults = int(vals[6])
   bflushlast = int(vals[7])
   bflushavg = float(vals[8])

   now = datetime.datetime.now()
   print "{:%d/%m/%y %H:%M:%S}".format(now), args.node, args.workload, args.phase, args.threads, insert, query, update, delete, getmore, command, faults, bflushlast, "{:.3f}".format(bflushavg)

if __name__ == "__main__":
   parser = argparse.ArgumentParser()
   parser.add_argument('-n', '--node', help="destination host", required=True)
   parser.add_argument('-w', '--workload', help="workload name [workload1|workload2|workload3]", required=True)
   parser.add_argument('-p', '--phase', help="workload phase [load|run]", required=True)
   parser.add_argument('-t', '--threads', help="number of threads", required=True)
   args = parser.parse_args()

   cmd = ["m", "shell", "2.6.3", args.node+"/ycsb", "--quiet", "stats.js"]

   output = subprocess.check_output(cmd)
   vals0 = map(float, output.split(' '))
   count = len(vals0)

   while True:
      output = subprocess.check_output(cmd)
      vals1 = map(float, output.split(' '))
      # all vals but last 2 are cumulative, so calculate the delta
      for i in range(count-2):
         vals0[i] = vals1[i]-vals0[i]
      vals0[count-2] = vals1[count-2]
      vals0[count-1] = vals1[count-1]
      printVals(args, vals0)
      vals0 = vals1
      time.sleep(1)

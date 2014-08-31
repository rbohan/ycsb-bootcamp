ss=db.serverStatus()
counters=ss.opcounters
extra=ss.extra_info
flush=ss.backgroundFlushing
print(counters.insert + " " + counters.query + " " + counters.update + " " + counters.delete + " " + counters.getmore + " " + counters.command + " " + extra.page_faults + " " + flush.last_ms + " " + flush.average_ms)

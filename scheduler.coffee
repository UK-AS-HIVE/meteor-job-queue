@ScheduleJob = (processorType, settings) -> #TODO exports?
  JobQueue.insert
    processor: processorType
    settings: settings
    submitTime: new Date()
    userId: '' #TODO make this make sense
    hostname: ''
    state: null
    status: 'pending'

Scheduler = {}
Scheduler.ScheduleJob = @ScheduleJob #for exporting

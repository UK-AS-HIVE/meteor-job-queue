Fiber = Npm.require 'fibers'

@ScheduleJobPipeline = (pipeline) ->
  parents = []
  for pipePart in pipeline
    currentPipePartIds = []
    for job in pipePart
      jobId = ScheduleJob job.processorType, parents, parents, job.settings
      currentPipePartIds.push jobId 
    parents = currentPipePartIds
      
@ScheduleJob = (processorType, parents, waitingOn, settings) -> #TODO exports?
  JobQueue.insert
    processor: processorType
    parents: parents
    waitingOn: waitingOn
    settings: settings
    submitTime: new Date()
    userId: '' #TODO make this make sense
    hostname: ''
    state: null
    status: 'pending'

Scheduler = {}
Scheduler.ScheduleJob = @ScheduleJob #for exporting
Scheduler.ScheduleJobPipeline = @ScheduleJobPipeline

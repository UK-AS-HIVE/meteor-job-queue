Fiber = Npm.require 'fibers'

ScheduleJobPipeline = (pipeline) ->
  #[{processorType: processorType, settings: settings}],
  #[[processorType, settings],[processorType, settings]...],
  #...]
  #TODO validate pipeline with schemas
  ###
  for pipelineIndex in [1..pipeline.length-1]
    out
  ###
  parents = []
  for pipePart in pipeline
    currentPipePartIds = []
    for job in pipePart
      currentPipePartIds.push ScheduleJob job.processorType, parents, parents, job.settings #non-obvious, but the second parents arguments is because we are still waitingOn them
    parents = currentPipePartIds
      
@ScheduleJob = (processorType, parents, waitingOn, settings) -> #TODO exports?
  console.log 'ScheduleJob has been called!'
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

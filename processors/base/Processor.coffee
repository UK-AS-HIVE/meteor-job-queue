@Processors = {}
class @Processors.Processor
  constructor: (@jobQueueId, @settings) ->
    console.log 'New ' + @constructor.name + ':'
    console.log @settings.file
    processor = this
    processorType = @constructor.name

  process: ->
    console.log 'Process the file here, a long running process'
  
  setStatus: (s) ->
    JobQueue.update {_id: @jobQueueId}, {$set: {status: s}}
    #if setting status to complete
    # remove my ID from any waitingOn fields #because we are finished waiting on me
  
  finish: ->
    #console.log 'DEBUG finish has been called'
    @setStatus 'done'
    JobQueue.update {waitingOn: @jobQueueId}, {$pull: {waitingOn: @jobQueueId}}
  
  @inputSchema: {}
  
  @outputSchema: {}

Processors = @Processors #we'll export the Processors variable

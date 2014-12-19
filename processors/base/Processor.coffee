@Processors = {}
class @Processors.Processor
  constructor: (@jobQueueId, @settings) ->
    console.log 'New ' + @constructor.name + ' constructed' 
    #console.log @settings
    #processor = this
    #processorType = @constructor.name

  process: ->
    return 'Long running process' #had returning 0, but apparently was returning false? or maybe
                                  #thats how tinytest was interpreting the 0 i gave it
  
  setStatus: (s) ->
    JobQueue.update {_id: @jobQueueId}, {$set: {status: s}}
  
  finish: ->
    #console.log 'DEBUG finish has been called'
    @setStatus 'done'
  
  @inputSchema: {}
  
  @outputSchema: {}

Processors = @Processors #we'll export the Processors variable

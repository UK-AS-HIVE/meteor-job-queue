if Meteor.isServer
  JobQueue.remove {}
  Tinytest.add 'Processor - constructor', (test) ->
    testProcessor = new Processors.Processor 'FooID', 
      file: 
        name: 'AaronFile'
        type: 'FakeFile'
        size: 25 
    test.isTrue testProcessor.jobQueueId is 'FooID' and 
      testProcessor.settings.file.name is 'AaronFile' and
      testProcessor.settings.file.type is 'FakeFile' and
      testProcessor.settings.file.size is 25

  Tinytest.add 'Processor - process()', (test) ->
    testProcessor = new Processors.Processor 'FooID', {}
    test.equal testProcessor.process(), 'Long running process', "process method did not ouput 'Long running process'"
  
  ###
  TODO check if they are instances of Simple Schema?
  Tinytest.add 'Processor - inputSchema', (test) ->
  Tinytest.add 'Processor - outputSchema', (test) ->
 
  Integration testing
  Tinytest.add 'Processor - setStatus()', (test) ->
  Tinytest.add 'Processor - finish()', (test) ->


  this isn't really a great test of this, but I guess it works
  ###
      
  ScheduleJob 'Processor', {id: 'parentId'}, {id: 'waitingonId'}, {name: 'test'}

  Tinytest.add 'Pipelines - ScheduleJob - processor', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    console.log job #debug
    test.isTrue job.processor is 'Processor'
  
  Tinytest.add 'Pipelines - ScheduleJob - parents', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.parents.id is 'parentId'

  Tinytest.add 'Pipelines - ScheduleJob - watingOn', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.waitingOn.id is 'waitingonId'

  Tinytest.add 'Pipelines - ScheduleJob - settings.name', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.settings.name is 'test'
  
  Tinytest.add 'Pipelines - ScheduleJob - submitTime', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.submitTime instanceof Date

  Tinytest.add 'Pipelines - ScheduleJob - userId', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.userId is ''

  Tinytest.add 'Pipelines - ScheduleJob - hostname', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.userId is ''

  Tinytest.add 'Pipelines - ScheduleJob - state', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.state is null

  Tinytest.add 'Pipelines - ScheduleJob - status', (test) ->
    job = JobQueue.findOne {settings: {name: 'test'}}
    test.isTrue job.status is 'pending'

  #TODO
  #Tinytest.add 'Pipelines - ScheduleJobPipeline', (test) ->

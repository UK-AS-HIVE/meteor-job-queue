numOfProcessorsRunning = 0
console.log process.env
port = parseInt (if process.env.hasOwnProperty 'ROOT_URL' then process.env['ROOT_URL'].replace /[^0-9]/g, '' else process.env['PORT'])
affinity = if port >= 4000 then 2 else 0 #TODO rename affinity to something else?
myHostName = process.env['HOSTNAME'] + ':' + port #process.pid #"test-computer-host-name"
global = this
Fiber = Npm.require 'fibers'

@CurrentUploads = {}

findRandomJob = () -> 
  if affinity > 0
    possibleJob = JobQueue.findOne {hostname: ''} #TODO make this work on some kind of schedule, not just find next randomly acceptable job
    if possibleJob and affinity > numOfProcessorsRunning 
      claim possibleJob
    else
      console.log 'Could not find any new jobs for me.'


claim = (job) ->
  console.log 'Attempting to claim job...'
  id = JobQueue.update {_id: job._id, hostname: ''}, {$set: {hostname: myHostName}} 
  if id
    numOfProcessorsRunning++
    console.log 'Claimed job with ID: ' + job._id
    fiber = Fiber ->
      id = job._id 
      processorClass = Processors[job.processor] 
      processor = new processorClass(id, job.settings)
      console.log processor
      output = {}
      #TODO check the to make sure the parentJobs of the processor are completed!
      try
        output = processor.process()
        context = processorClass.outputSchema.namedContext('processorOutput')
        if not context.validate output
          console.log 'Processor output failed schema validation for job ' + id
          console.log context.invalidKeys()
      catch error
        console.log error
        JobQueue.update {_id: id}, {$set: {status: 'error'}}
      finally
        numOfProcessorsRunning--
        console.log 'Job Completed. CURRENTLY COMPUTING: ' + numOfProcessorsRunning
        console.log 'Looking for new jobs...'
        findRandomJob()  
    fiber.run() #Warning: non-blocking, gets yielded out of 
  else
    console.log 'Could not accept pending job with ID: ' + job._id
    findRandomJob() #will keep looking for jobs as long as it can find one without a host

Meteor.startup ->
  console.log 'myHostName: ' + myHostName
  console.log 'concurrent process limit: ' + affinity
  cursor = JobQueue.find { hostname: {$in: ['', myHostName]}} #TODO why hostname?
  observer = cursor.observe
    added: (document) ->
      console.log 'A job was added! Can I take it? Lets see...'
      console.log 'Process load for this node: ' + numOfProcessorsRunning + '/' + affinity
      if (numOfProcessorsRunning < affinity and document.processor!= 'UploadProcessor') or 
      (document.processor is 'UploadProcessor' and port < 4000) 
        claim document
      else
        console.log "Could not accept added job with ID: " + document._id
    ###changed: (newDocument, oldDocument) -> #TODO this does nothing. Do we need this? Why?
      return
      if numOfProcessorsRunning < affinity
        id = JobQueue.update {_id: newDocument._id, hostname: ''}, {$set: {hostname: myHostName}}
        if id
          claim newDocument
      console.log "a document on the job queue was changed"###
    removed: (oldDocument) ->
      console.log "A job has been removed from the Job Queue."
      #console.log "Job with ID " + oldDocument._id + " has been removed from the Job Queue."

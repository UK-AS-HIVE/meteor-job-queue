numOfProcessorsRunning = 0
console.log process.env
port = parseInt (if process.env.hasOwnProperty 'ROOT_URL' then process.env['ROOT_URL'].replace /[^0-9]/g, '' else process.env['PORT'])
affinity = if port >= 4000 then 2 else 0 #TODO rename affinity to something else?
myHostName = process.env['HOSTNAME'] + ':' + port #process.pid #"test-computer-host-name"
global = this
Fiber = Npm.require 'fibers'

@CurrentUploads = {}
ReadyAndWaiting = []

findRandomJob = () -> 
  if affinity > 0
    possibleJob = JobQueue.findOne {hostname: '', waitingOn: {$size: 0}} #TODO make this work on some kind of schedule, not just find next randomly acceptable job
    if possibleJob
      attemptClaim possibleJob._id
    else
      console.log "Just finished a job, but it doesn't look like theres any others for me."

attemptClaim = (id) ->
  document = JobQueue.findOne {_id: id}
  #console.log document
  if (numOfProcessorsRunning < affinity and document.processor != 'UploadProcessor') or (document.processor is 'UploadProcessor' and port < 4000) 
    console.log "Job looks acceptable. Trying to claim a " + document.processor
    claim id
  else
    console.log "Could not accept added job with ID: " + id + ". I'm working too hard!"

claim = (id) ->
  console.log 'Attempting to claim job...'
  numChanged = JobQueue.update {_id: id, hostname: ''}, {$set: {hostname: myHostName}}  
  if numChanged > 0
    job = JobQueue.findOne {_id: id} 
    numOfProcessorsRunning++
    console.log 'Claimed job with ID: ' + job._id
    fiber = Fiber -> 
      processorClass = Processors[job.processor] 
      processor = new processorClass(id, job.settings)
      console.log processor
      output = {}
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
    console.log 'Could not accept pending job with ID: ' + id + '. Looking for new job.'
    findRandomJob() #will keep looking for jobs as long as it can find one without a host

Meteor.startup ->
  console.log 'myHostName: ' + myHostName
  console.log 'concurrent process limit: ' + affinity

  statusPendingCursor = JobQueue.find {status: 'pending'}
  statusPendingCursor.observeChanges
    changed: (id, fields) -> 
      if fields.hasOwnProperty('waitingOn')
        if fields.waitingOn.length is 0
          attemptClaim id
  
  noHostCursor = JobQueue.find {hostname: ''}
  noHostCursor.observeChanges
    added: (id, fields) ->
      console.log 'Added: ' + id
      #console.log 'A job was added! Can I take it? Lets see...'
      console.log 'Process load for this node: ' + numOfProcessorsRunning + '/' + affinity
      if fields.waitingOn.length is 0
        attemptClaim id
      else
        console.log 'The job is still waiting on some others to finish!'
  
  
  ###cursor = JobQueue.find { hostname: {$in: ['', myHostName]}} #TODO why hostname?
  observer = cursor.observe
    added: (document) ->
      console.log 'A job was added! Can I take it? Lets see...'
      console.log 'Process load for this node: ' + numOfProcessorsRunning + '/' + affinity
      if document.waitingOn.length == 0 #wrap in another function?
        attemptClaim document
    removed: (oldDocument) ->
      console.log "A job has been removed from the Job Queue."###

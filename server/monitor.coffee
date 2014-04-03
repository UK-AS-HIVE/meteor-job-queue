numOfProcessorsRunning = 0
console.log process.env
port = parseInt (if process.env.hasOwnProperty 'ROOT_URL' then process.env['ROOT_URL'].replace /[^0-9]/g, '' else process.env['PORT'])
affinity = if port >= 4000 then 2 else 0
myHostName = process.env['HOSTNAME'] + ':' + port #process.pid #"test-computer-host-name"
global = this
Fiber = Npm.require 'fibers'

(exports ? this).CurrentUploads = {}

claim = (job) ->
  console.log 'Attempting to claim job...'
  id = JobQueue.update {_id: job._id, hostname: ''}, {$set: {hostname: myHostName}} 
  if id
    numOfProcessorsRunning++
    console.log 'Claimed!'
    #future = new Future()
    fiber = Fiber ->
      id = job._id 
      processorClass = global[job.processor] 
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
        #TODO recheck jobqueue for jobs to claim
        console.log 'Looking for new jobs...'
        possibleJob = JobQueue.findOne {hostname: ''} 
        if possibleJob and affinity > numOfProcessorsRunning
          #numOfProcessorsRunning++ #do this right away to stop other things from thinking it can take
          claim possibleJob
        else
          console.log 'Could not find any new jobs for me.'
    
    fiber.run() #Warning: non-blocking
    #future.wait() 
  else
    console.log 'Could not accept job. Its possible some other node got it before me.'

Meteor.startup ->
  console.log 'myHostName: ' + myHostName
  console.log 'concurrent process limit: ' + affinity
  cursor = JobQueue.find { hostname: {$in: ['', myHostName]} }#, {fields: ['processor', 'hostname', '_id']} TODO why hostname?
  observer = cursor.observe #TODO did not catch when I manually inserted to jobqueue from console
    added: (document) ->
      #console.log Fiber.current
      console.log 'A job was added! Can I take it? Lets see...'
      console.log 'Process load for this node: ' + numOfProcessorsRunning + '/' + affinity
      if numOfProcessorsRunning < affinity or document.processor is 'UploadProcessor' #did we want compute nodes to upload maybe? I thought we discussed only web nodes, but maybe not
        claim document
        ### console.log 'Attempting to claim job...'
        id = JobQueue.update {_id: document._id, hostname: ''}, {$set: {hostname: myHostName}}
        if id #ie if the document was succesfully updated to reflect that we have taken it
          #document = JobQueue.findOne {_id: document._id}
          claim document
        #if numOfProcessorsRunning == affinity then observer.stop()###
      else
        console.log "Could not accept job!"
    changed: (newDocument, oldDocument) ->
      return
      if numOfProcessorsRunning < affinity
        id = JobQueue.update {_id: newDocument._id, hostname: ''}, {$set: {hostname: myHostName}}
        if id
          #newDocument = JobQueue.findOne {_id: document._id}
          claim newDocument
        #if numOfProcessorsRunning == affinity then observer.stop()
      console.log "a document on the job queue was changed"
    removed: (oldDocument) ->
      console.log "a document was removed from the job queue"

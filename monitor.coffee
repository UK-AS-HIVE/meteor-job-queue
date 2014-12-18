numOfProcessorsRunning = 0
port = parseInt (if process.env.hasOwnProperty 'ROOT_URL' then process.env['ROOT_URL'].replace /[^0-9]/g, '' else process.env['PORT'])

affinity = Npm.require('os').cpus().length

#If this is a web node, reserve a core for serving web clients? Maybe drop this to 1 core?
if Meteor.settings.jobQueue.serverType == "web"
  affinity--

myHostName = process.env['HOSTNAME'] + ':' + port 
global = this
Fiber = Npm.require 'fibers'

console.log 'Port: ' + port
console.log 'Affinity: ' + affinity

findOldestJob = () -> 
  if affinity > 0
    possibleJob = JobQueue.findOne {hostname: ''}, {sort: ['submitTime', 'ascending']}
    if possibleJob
      console.log "Found a possible job."
      initiateClaim possibleJob._id
    else
      console.log "Just finished a job, but it doesn't look like theres any others for me."

initiateClaim = (id) ->
  document = JobQueue.findOne {_id: id}
  if (numOfProcessorsRunning < affinity)
    console.log "Job looks acceptable. Trying to claim job with ID: " + id
    claim id
  else
    console.log "Job with ID: " + id + " was not acceptable."

moveToStandardCwd = ->
  while process.cwd().indexOf('.meteor') isnt -1
    process.chdir '..'

claim = (id) ->
  console.log 'Attempting to claim job...'
  moveToStandardCwd()
  numChanged = JobQueue.update {_id: id, hostname: ''}, {$set: {hostname: myHostName}}  
  if numChanged > 0
    job = JobQueue.findOne {_id: id} 
    numOfProcessorsRunning++
    console.log 'Claimed job with ID: ' + job._id
    fiber = Fiber -> 
      processorClass = Processors[job.processor] 
      if processorClass is undefined
        console.log "Couldn't find the processor " + job.processor + ". Did you make a typo?"
      processor = new processorClass(id, job.settings)
      output = {}
      try
        output = processor.process()
        context = processorClass.outputSchema.namedContext('processorOutput')
        if not context.validate output
          console.log 'Processor output failed schema validation for job ' + id
          console.log context.invalidKeys()
          JobQueue.update {_id: id}, {$set: {status: 'failed validation'}}
        else
          JobQueue.update {_id: id} , {$set: {output: output}}

      catch error
        console.log 'ERROR: ' + error
        JobQueue.update {_id: id}, {$set: {status: 'error'}}

      finally
        numOfProcessorsRunning--
        console.log 'Job Completed! Looking for new jobs.'  
        findOldestJob()  
    fiber.run() #Warning: non-blocking, gets yielded out of 
  else
    console.log 'Could not accept job with ID: ' + id + '. Looking for new job.'
    findOldestJob() #will keep looking for jobs as long as it can find one without a host

Meteor.startup ->
  console.log 'myHostName: ' + myHostName
  console.log 'concurrent process limit: ' + affinity

  statusPendingCursor = JobQueue.find {status: 'pending'}
  statusPendingCursor.observeChanges
    changed: (id, fields) -> 
      initiateClaim id
  
  noHostCursor = JobQueue.find {hostname: ''}
  noHostCursor.observeChanges
    added: (id, fields) ->
      console.log 'Added: ' + id
      initiateClaim id

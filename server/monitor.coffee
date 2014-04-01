numOfProcessorsRunning = 0
console.log process.env
port = parseInt (if process.env.hasOwnProperty 'ROOT_URL' then process.env['ROOT_URL'].replace /[^0-9]/g, '' else process.env['PORT'])
affinity = if port >= 4000 then 2 else 0
myHostName = process.env['HOSTNAME'] + ':' + port #process.pid #"test-computer-host-name"
window = this

(exports ? this).CurrentUploads = {}

claim = (job) ->
  Fiber = Npm.require 'fibers'
  fiber = new Fiber ->
    #job = JobQueue.findOne {_id: id, hostname: myHostName}
    id = job._id
    console.log '*** Claiming a job: ' + job.settings.file.name
    console.log job
    #parse the object and creat an appropriate processor
    processorClass = window[job.processor] 
    processor = new processorClass(id, job.settings)
    console.log processor
    numOfProcessorsRunning++
    output = {}
    #TODO check the to make sure the parentJobs of the processor are completed!
     
    try
      output = processor.process()
      if not processorClass.outputSchema.namedContext('processorOutput').validate output
        console.log 'Processor output failed schema validation for job ' + id
    catch error
      console.log error
      JobQueue.update {_id: id}, {$set: {status: 'error'}}
    finally
      numOfProcessorsRunning--
      console.log 'CURRENTLY COMPUTING: ' + numOfProcessorsRunning
  fiber.run()

Meteor.startup ->
  console.log 'myHostName: ' + myHostName
  console.log 'concurrent process limit: ' + affinity
  cursor = JobQueue.find { hostname: {$in: ['', myHostName]} }#, {fields: ['processor', 'hostname', '_id']}
  observer = cursor.observe #TODO did not catch when I manually inserted to jobqueue from console
    added: (document) ->
      console.log Npm.require('fibers').current
      console.log 'A job was added! Can I take it? Lets see...'
      console.log 'Process load for this node: ' + numOfProcessorsRunning + '/' + affinity
      if numOfProcessorsRunning < affinity or document.processor is 'UploadProcessor' #did we want compute nodes to upload maybe? I thought we discussed only web nodes, but maybe not
        console.log 'Attempting to claim job...'
        id = JobQueue.update {_id: document._id, hostname: ''}, {$set: {hostname: myHostName}}
        if id #ie if the document was succesfully updated to reflect that we have taken it
          #document = JobQueue.findOne {_id: document._id}
          claim document
        #if numOfProcessorsRunning == affinity then observer.stop()
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

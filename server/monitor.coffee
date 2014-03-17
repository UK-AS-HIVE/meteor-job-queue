numOfProcessorsRunning = 0
affinity = 1
myHostName = "test-computer-host-name"
window = this

(exports ? this).CurrentUploads = {}


claim = (id) ->
  job = JobQueue.findOne {_id: id, hostname: myHostName}
  console.log job
  #parse the object and creat an appropriate processor
  processor = new window[job.processor](id, job.settings)
  console.log processor
  numOfProcessorsRunning++
  processor.process()
  numOfProcessorsRunning--


Meteor.startup ->
  cursor = JobQueue.find { hostname: {$in: ['', myHostName]} }, {fields: ['hostname', '_id']}
  observer = cursor.observe
    added: (document) ->
      if numOfProcessorsRunning < affinity
        id = JobQueue.update {_id: document._id, hostname: ''}, {$set: {hostname: myHostName}}
        if id
          claim document._id
        if numOfProcessorsRunning == affinity then observer.stop()
        #console.log "claiming this process! ID: " + id
      console.log "a document was added to the job queue"
      #console.log document
    changed: (newDocument, oldDocument) ->
      if numOfProcessorsRunning < affinity
        #id = JobQueue.update {_id: newDocument._id, hostname: ''}, {$set: {hostname: myHostName}}
        claim newDocument._id
        if numOfProcessorsRunning == affinity then observer.stop()
      console.log "a document on the job queue was changed"
      #console.log newDocument
    removed: (oldDocument) ->
      console.log "a document was removed from the job queue"
      #console.log oldDocument

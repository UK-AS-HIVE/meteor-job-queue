numOfProcessorsRunning = 0
affinity = 1
myHostName = "test-computer-host-name"
claim = (id) ->
  job = JobQueue.find({_id: id, hostname: myHostName}).fetch
  console.log job
  #parse the object and creat an appropriate processor
  
 
Meteor.startup ->
  cursor = JobQueue.find {}
  observer = cursor.observe 
    added: (document) ->
      if numOfProcessorsRunning < affinity
        id = JobQueue.update {_id: document._id, hostname: ''}, {$set: {hostname: myHostName}}
        claim document._id
        if numOfProcessorsRunning == affinity then observer.stop()
        #console.log "claiming this process! ID: " + id
      console.log "a document was added to the job queue"
      #console.log document
    changed: (newDocument, oldDocument) ->
      console.log "a document on the job queue was changed"
      #console.log newDocument
    removed: (oldDocument) ->
      console.log "a document was removed from the job queue"
      #console.log oldDocument

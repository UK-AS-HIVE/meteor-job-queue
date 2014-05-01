###
  TODO support other encodings:
  http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
###
Future = Npm.require('fibers/future')
Meteor.methods
  meteorFileUpload: (mf) ->
    @unblock() #I'm not confident this does anything

    ###TODO Find by ID somehow. Another thing that might work would be checking the CurrentUploads
    object (it's global) for the serializeable file (we use that as the key on the CurrentUploads
    object) before we find this job. This way we'd know we have a file currently being uploaded.
    However, I still don't like it, because while serializeable is an okay key, it's not
    guaranteed unique. I'd like to either use md5 (also not perfect) or some other system.###
    thisJob = JobQueue.find  
      "settings.file.name": mf.name,
      processor: 'UploadProcessor'

    exists = thisJob.count() > 0
    serializableMeteorFile = _.pick mf, 'name', 'type', 'size'    #_.omit doesn't seem to work, 
                                                                  #but _.pick works fine

    #Create a new future for the UploadProcessor to wait on. We'll return it when we get the next 
    #chunk in.
    newFuture = new Future()
    currentUploadsKey = JSON.stringify serializableMeteorFile

    if exists
      oldFuture = CurrentUploads[currentUploadsKey]['future']

    CurrentUploads[currentUploadsKey] = 
      'meteorFile': mf,
      'future': newFuture

    if exists
      oldFuture.return() 
    else  
      #TODO affiliate jobId with the processor (this probably needs to actuall happen in claim)
      jobId = ScheduleJobPipeline [
        [{processorType: 'UploadProcessor', settings: {file: serializableMeteorFile}}],
        [{processorType: 'TikaProcessor', settings: {file: serializableMeteorFile}}, {processorType: 'VideoTranscodeProcessor', settings: {file: serializableMeteorFile, targetType: 'blah'}}],
        [{processorType: 'Md5GenProcessor', settings: {file: serializableMeteorFile}}]]

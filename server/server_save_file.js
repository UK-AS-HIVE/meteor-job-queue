/**
 * TODO support other encodings:
 * http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
 */

Meteor.methods({
  meteorFileUpload: function(mf) {
    console.log('Upload request made from client: ' + mf.name +': ' + mf.uploadProgress +'% done. This does not mean that we are actually uploading the file, this is simply the chunk we have been handed');

    thisJob = JobQueue.find({
      "settings.file.name": mf.name,
      processor: 'UploadProcessor'
    });

    //TODO it looks like a collection of existing processors may be useful. This could be bent to support our need for continuation (
    // Let's just hang on to the important aspects. This is for putting into CurrentUploads so we can find it and start it again. 
    serializableMeteorFile = _.pick(mf, 'name', 'type', 'size');
    //serializableFile = _.omit(mf, 'data');  // For some reason, _.pick works but _.omit does not
    
    //Create a new future for the UploadProcessor to wait on. We'll return it when we get the next chunk in.
    var Future = Npm.require('fibers/future');
    var newFuture = new Future();
    var currentUploadsKey = JSON.stringify(serializableMeteorFile);
    //Get a handle for our old future, if one exists
    if (thisJob.count() > 0)
      var oldFuture = CurrentUploads[currentUploadsKey]['future'];
    CurrentUploads[currentUploadsKey] = 
      {'meteorFile': mf,
       'future': newFuture};
    //Return the old future so the upload processor can stop waiting.
    if (thisJob.count() > 0)
      oldFuture.return();
   
    //TODO: learn how this works.
    //  How does the meteor file upload itself? It handles the actually uploading. We catch the uploaded chunk in this meteorFileUpload meteor method, and give the chunk to a global object.
    //  The upload processor simply takes the chunk from this global object when we return the appropriate future! 
    if (thisJob.count() > 0) //this shouldn't ever happen. We should improve the querey for thisJob
    { 
      //If we already have this job on the queue, then when to update it with our progress.  
      JobQueue.update({'settings.file.name': mf.name, processor: 'UploadProcessor'},
        {$set: {status: mf.end === mf.size ? 'done' : mf.uploadProgress+'%' }}); //redundant, the processor sets itself to done when it's completed
      console.log("updating job");
    }
    else
    {  
      //Otherwise, we need to put the job on the queue.
      //I kind of want to affiliate the job id with the processor. Maybe seperate the processes of actually making the processor and of scheduling it? We instantiate upload in claim
      jobId = ScheduleJob('UploadProcessor', [], [], { file: serializableMeteorFile });
 
      console.log('added to the queue in meteorFileUpload with id ' + jobId);
    }
  }
});

Meteor.startup(function() {
  cwd = process.cwd();
  console.log(cwd);
  if (cwd.indexOf('.meteor') != -1) {
    console.log('Running unbundled, moving out of .meteor dir');
    process.chdir('../../../../..'); //this is a nodejs function. We're on the server, remember?
  }
  console.log('cwd: ' + process.cwd());
  //fs.symlinkSync('../../../../uploads', '.meteor/local/build/uploads');
});

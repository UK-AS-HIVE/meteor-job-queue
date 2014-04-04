/**
 * TODO support other encodings:
 * http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
 */
var Future = Npm.require('fibers/future');
Meteor.methods({
  meteorFileUpload: function(mf) {
    this.unblock();
    console.log('Upload request made from client: ' + mf.name +': ' + mf.uploadProgress +'% done.');

    thisJob = JobQueue.find({
      "settings.file.name": mf.name,
      processor: 'UploadProcessor'
    });
    var exists = thisJob.count() > 0;

    //Helps for putting into database
    serializableMeteorFile = _.pick(mf, 'name', 'type', 'size');
    //serializableFile = _.omit(mf, 'data');  // For some reason, _.pick works but _.omit does not
    
    //Create a new future for the UploadProcessor to wait on. We'll return it when we get the next chunk in.
    var newFuture = new Future();
    var currentUploadsKey = JSON.stringify(serializableMeteorFile);
    //Get a handle for our old future, if one exists
    if (exists)
      var oldFuture = CurrentUploads[currentUploadsKey]['future'];
    CurrentUploads[currentUploadsKey] = 
      {'meteorFile': mf,
       'future': newFuture};
    //Return the old future so the upload processor can stop waiting.
    if (exists)
      oldFuture.return();
   
    //TODO: learn how this works.
    //  How does the meteor file upload itself? It handles the actually uploading. We catch the uploaded chunk in this meteorFileUpload meteor method, and give the chunk to a global object.
    //  The upload processor simply takes the chunk from this global object when we return the appropriate future! 
    if (exists) 
    { 
      //If we already have this job on the queue, then when to update it with our progress.  
      JobQueue.update({'settings.file.name': mf.name, processor: 'UploadProcessor'},
        {$set: {status: mf.end === mf.size ? 'done' : mf.uploadProgress+'%' }}); //TODO the processors finish command should set to done
      //console.log("updating job");
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

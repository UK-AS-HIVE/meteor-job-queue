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
    CurrentUploads[JSON.stringify(serializableMeteorFile)] = mf;
   
    //TODO: learn how this works.
    //  How does the meteor file upload itself? We assign our first meteor file object (mf) to our upload processor, but then don't change it after that.
    //  How does mf know automatically to save itself? We never give it to the UploadProcessor we are running, nor do we make a new one for this meteor file. 
    if (thisJob.count() > 0) //this shouldn't ever happen. We should improve the querey for thisJob
    { 
      //My recommendation is rename UploadProcessor to UploadChunkProcessor. We can still hide this from the user on the front end, but it would make this problem a lot easier.
      //Don't want to do that? Okay. Then we need to affiliate this job with our specific UploadProcessor somehow. Right now, I don't think this is possible. We use the JobQueueId as the processor's id,
      //but we don't have a collection of the processors anywhere; there's no way to grab it. I guess for now we can use CurrentUploads.
      
      //here we want to make our upload processor deal with chunks
          JobQueue.update({'settings.file.name': mf.name, processor: 'UploadProcessor'},
        {$set: {status: mf.end === mf.size ? 'done' : mf.uploadProgress+'%' }}); //redundant, the processor sets itself to done when it's completed
      console.log("updating job");
    }
    else
    {  
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

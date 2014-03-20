/**
 * TODO support other encodings:
 * http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
 */

Meteor.methods({
  meteorFileUpload: function(mf) {
    console.log('Uploading '+ mf.name +': ' + mf.uploadProgress +'% done');

    jq = JobQueue.find({
      "settings.file.name": mf.name,
      processor: 'UploadProcessor'
    });

    if (jq.count() > 0)
    { //will this ever be equal to something other than 1 if it's > 0?
      JobQueue.update({'settings.file.name': mf.name, processor: 'UploadProcessor'},
        {$set: {status: mf.end === mf.size ? 'done' : mf.uploadProgress+'%' }});
      console.log("updating job");
    }
    else
    {
      // Let's just hang on to the important aspects
      serializableFile = _.pick(mf, 'name', 'type', 'size');
      //serializableFile = _.omit(mf, 'data');  // For some reason, _.pick works but _.omit does not
      
      CurrentUploads[JSON.stringify(serializableFile)] = mf;

      jobId = ScheduleJob('UploadProcessor', [], { file: serializableFile });
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

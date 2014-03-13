/**
 * TODO support other encodings:
 * http://stackoverflow.com/questions/7329128/how-to-write-binary-data-to-a-file-using-node-js
 */

Meteor.methods({
  meteorFileUpload: function(mf) {
    console.log('Uploading '+ mf.name +': ' + mf.uploadProgress +'% done');
    all = JobQueue.find({}).count();
    console.log(all);
    jq = JobQueue.find({
      "settings.name": mf.name
      //settings: {file: {name: mf.name}}
      //processor: 'UploadProcessor'
    }).fetch();
    console.log(jq.length);
    if (jq.length > 0)
    { //will this ever be equal to something other than 1 if it's > 0?
      //JobQueue.update({settings: {file: mf.name}, processor: 'UploadProcessor'},
        //{$set: {status: mf.uploadProgress}});
      console.log("updating job");
    }
    else
    {
      ScheduleJob('UploadProcessor', [], _.extend({}, mf));
      console.log('added to the queue in meteorFileUpload');
    }
  }
});

Meteor.startup(function() {
  //fs = Npm.require('fs');
  process.chdir('../../../../..'); //this is a nodejs function. We're on the server, remember?
  console.log('cwd: ' + process.cwd());
  //fs.symlinkSync('../../../../uploads', '.meteor/local/build/uploads');
});

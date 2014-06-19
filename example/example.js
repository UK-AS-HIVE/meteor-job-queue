if (Meteor.isClient) {

  UI.body.events({
    'click button#add-job': function() {
      Meteor.call('addExampleJobs', 1);
    },
    'click button#add-hundred-jobs': function() {
      Meteor.call('addExampleJobs', 100)
    },
    'click button#clear-jobs': function() {
      Meteor.call('clearExampleJobs');
    }
  });

  Template.queue.helpers({
    job: function() {
      j = JobQueue.find();
      console.log(j);
      return j;
    },
    inspect: function(o) {
      return JSON.stringify(o);
    }
  });
}

if (Meteor.isServer) {

  Meteor.startup(function() {
    JobQueue.remove({});
  });

  Meteor.methods({
    addExampleJobs: function(n) {
      for (i=0; i<n; ++i)
        Scheduler.ScheduleJob('Md5GenProcessor', [], [], {file: {name: 'testfile.jpg'}});
    },
    clearExampleJobs: function() {
      JobQueue.remove({status: {$in: ['done', 'error']} });
    }
  });
}

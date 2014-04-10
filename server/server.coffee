Meteor.publish 'jobQueue', ->
  JobQueue.find {}, {limit: 100}
      
Meteor.startup ->
  JobQueue.remove {}

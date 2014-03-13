Meteor.publish 'jobQueue', ->
  JobQueue.find {}, {limit: 100}
      
Meteor.startup ->
  JobQueue.remove {}
  ###async = Npm.require 'async'
  file_process_queue = async.queue process_file, 5
  file_process_queue.drain = ->
    console.log 'Finished processing all files'###

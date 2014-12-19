@BenchmarkResults = new Meteor.Collection 'benchmarkResults'

if Meteor.isClient
  Template.body.events
    'click button#run-benchmarks': (e,tpl) ->
      Meteor.call 'runBenchmarks'

  Template.body.helpers
    benchmarkResults: -> BenchmarkResults.find {}
    job: -> JobQueue.find {}
    inspect: (o) -> JSON.stringify o

if Meteor.isServer
  Meteor.startup ->
    JobQueue.remove {}
    BenchmarkResults.remove {}
    JobQueue.startupWorker()

  Meteor.methods
    'runBenchmarks': ->
      fs = Npm.require 'fs'
      path = process.cwd()
      if path.lastIndexOf('.meteor') > 0
        path = path.substr(0, path.lastIndexOf('.meteor'))
      console.log 'BENCHMARK: reading files from ' + path

      BenchmarkResults.insert
        benchmarkName: 'hive:job-queue md5'
        startTime: new Date()
        endTime: null

      UpdateBenchmarkResults = ->
        currentStats =
          totalCount: JobQueue.find().count()
          pendingCount: JobQueue.find({status: 'pending'}).count()
          activeCount: JobQueue.find({status: 'processing'}).count()
          doneCount: JobQueue.find({status: {$in: ['done', 'error']}}).count()
        BenchmarkResults.update {benchmarkName: 'hive:job-queue md5'}, {$set: currentStats}
        if currentStats.totalCount > currentStats.doneCount
          Meteor.setTimeout UpdateBenchmarkResults, 500
        else
          BenchmarkResults.update {benchmarkName: 'hive:job-queue md5'}, {$set: {endTime: new Date()}}
      Meteor.setTimeout UpdateBenchmarkResults, 500

      for f in fs.readdirSync(path+'/public')
        console.log 'BENCHMARK: scheduling ' + f
        Scheduler.ScheduleJob 'Md5GenProcessor', [], [],
          file:
            name: path+'public/'+f


@BenchmarkResults = new Meteor.Collection 'benchmarkResults'

if Meteor.isClient
  Template.body.events
    'click button#run-benchmarks': (e,tpl) ->
      Meteor.call 'runBenchmarks'

  Template.body.helpers
    benchmarkResults: -> BenchmarkResults.find {}, {limit: 3, sort: {time: -1}}
    job: -> JobQueue.find {}
    inspect: (o) -> JSON.stringify o
    jobsPerSecond: ->
      br = BenchmarkResults.find().fetch()
      elapsed = br[br.length-1].time - br[0].time
      seconds = elapsed / 1000
      br[br.length-1].doneCount / seconds
    lineSegment: ->
      br = BenchmarkResults.find().fetch()
      if br.length > 0
        console.log 'br.length', br.length
        last = br[br.length-1]
        end = last.time
        start = br[0].time
        total = end - start
        console.log 'total', total
        return br.map (o, i) ->
          if i<br.length-1
            x1: 480*(o.time - start)/total
            y1: 90 * (1 - o.pendingCount/last.totalCount)
            x2: 480*(br[i+1].time - start)/total
            y2: 90 * (1 - br[i+1].pendingCount/last.totalCount)
          else
            null
      else
        console.log 'no data for line segments'

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

      UpdateBenchmarkResults = ->
        currentStats =
          totalCount: JobQueue.find().count()
          pendingCount: JobQueue.find({status: 'pending'}).count()
          activeCount: JobQueue.find({status: 'processing'}).count()
          doneCount: JobQueue.find({status: {$in: ['done', 'error']}}).count()
        BenchmarkResults.insert _.extend currentStats, {benchmarkName: 'hive:job-queue md5', time: new Date()}
        if currentStats.totalCount > currentStats.doneCount
          Meteor.setTimeout UpdateBenchmarkResults, 500
      Meteor.setTimeout UpdateBenchmarkResults, 5000

      for i in [0..100]
        for f in fs.readdirSync(path+'/public')
          console.log 'BENCHMARK: scheduling ' + f
          Scheduler.ScheduleJob 'Md5GenProcessor',
            file:
              name: path+'public/'+f
            outputfile:
              name: path+'thumbnails/'+f.substr(0,f.lastIndexOf('.')) + '_thumbnail.jpg'


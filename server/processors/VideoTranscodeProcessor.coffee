class Processors.VideoTranscodeProcessor extends Processors.Processor  
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'
    fs = Npm.require 'fs'

    durationInSeconds = null

    ffmpegFuture = new Future()
    fileName = @settings.file.name
    targetType = @settings.targetType
    outputTypes = ['avi'] #TODO figure out better way to attatch this to class (prototype, right?)
    if targetType not in outputTypes
      console.log 'VideoTranscodeProcessor: targetType not supported. Defaulting to avi'
      targetType = 'avi'
    console.log 'About to begin processing.'
    ffmpeg = spawn 'ffmpeg', ['-i', './uploads/' + fileName, '-y', './uploads/' + fileName.substr(0, fileName.indexOf('.'))  + '.' + targetType]

    processData = ''
    self = @
    ffmpeg.stderr.on 'data', Meteor.bindEnvironment (data) ->
      processData = processData+data
      if durationInSeconds is null
        dur = processData.match /Duration: (\d{2,}):(\d{2}):(\d{2}).(\d{2,})/
        if dur?
          durationInSeconds = 3600*parseInt(dur[1]) + 60*parseInt(dur[2]) + parseFloat(dur[3] + '.' + dur[4])
          processData = ''
      else
        time = processData.match /time=(\d{2,}):(\d{2}):(\d{2}).(\d{2,}) bitrate=/
        if time? && durationInSeconds#?
          currentTime = 3600*parseInt(time[1]) + 60*parseInt(time[2]) + parseFloat(time[3] + '.' + time[4])
          percent = Math.floor(currentTime*100/durationInSeconds)
          processData = ''
          self.setStatus percent + '%'

    ffmpeg.on 'close', (code, signal) ->
      try
        console.log 'Video transcoding successful!'
        ffmpegFuture.return {}
      catch e
        console.log 'Error during video transcoding.'
        ffmpegFuture.return 1 #TODO different return for error?

    @setStatus 'processing'

    if ffmpegFuture.wait() is 1
      @setStatus 'error'
    else
      console.log 'Finished with this VideoTranscodeProcessor!'
      @finish()

    return _.pick @settings, 'file' #TODO this is the input file. not good for output schema (always return?)

  @outputSchema: new SimpleSchema
    file:
      type: Object
    'file.name':
      type: String
    'file.type':
      type: String
      #allowedValues: ['avi'] #TODO this should really be tethered to outputTypes somehow
    'file.size':
      type: Number

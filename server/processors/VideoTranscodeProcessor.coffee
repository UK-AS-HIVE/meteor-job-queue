class @VideoTranscodeProcessor extends @Processor  
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'
    fs = Npm.require 'fs'

    ffmpegFuture = new Future() 
    fileName = @settings.file.name
    targetType = @settings.targetType
    outputTypes = ['avi'] #TODO figure out better way to attatch this to class (prototype, right?)
    if targetType not in outputTypes
      console.log 'VideoTranscodeProcessor: targetType not supported. Defaulting to avi'
      targetType = 'avi'
    console.log 'About to begin processing.'
    ffmpeg = spawn 'ffmpeg', ['-i', './uploads/' + fileName, './uploads/' + fileName.substr(0, fileName.indexOf('.'))  + '.' + targetType]#, {cwd:'//home/AD/arst238/meteor-job-queue/uploads/'} #TODO fix the cwd hack
    ffmpeg.on 'close', (code, signal) ->
      try
        console.log 'Video transcoding successful!'
        ffmpegFuture.return {}
      catch e
        console.log 'Error during video transcoding.'
        ffmpegFuture.return {} #TODO different return for error?
    @setStatus 'processing'
    ffmpegFuture.wait()
    console.log 'Finished with this VideoTranscodeProcessor!'

    @finish()
    return _.pick @settings, 'file' #TODO this is the input file. not good for output schema

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

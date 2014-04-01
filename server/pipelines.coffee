Fiber = Npm.require 'fibers'

ScheduleJobPipeline = (pipeline) ->
  #[{processorType: processorType, settings: settings],
  #[[processorType, settings],[processorType, settings]...],
  #...]
  #TODO validate pipeline with schemas
  ###
  for pipelineIndex in [1..pipeline.length-1]
    out
  ###
  parents = []
  for pipePart in pipeline
    currentPipePartIds = []
    for job in pipePart
      currentPipePartIds.push ScheduleJob job.processorType, parents, parents, job.settings #non-obvious, but the second parents arguments is because we are still waitingOn them
    parents = currentPipePartIds
      
(exports ? @).ScheduleJob = (processorType, parents, waitingOn, settings) ->
  console.log 'ScheduleJob has been called!'
  JobQueue.insert
    processor: processorType
    parents: parents
    waitingOn: waitingOn
    settings: settings
    submitTime: new Date()
    userId: '' #TODO make this make sense
    hostname: ''
    state: null
    status: 'pending'

class Processor
  constructor: (@jobQueueId, @settings) ->
    console.log 'New ' + @constructor.name + ':'
    console.log @settings.file
    processor = this
    processorType = @constructor.name

  process: ->
    console.log 'Process the file here, a long running process'
  
  setStatus: (s) ->
    JobQueue.update {_id: @jobQueueId}, {$set: {status: s}}
    #if setting status to complete
    # remove my ID from any waitingOn fields #because we are finished waiting on me
  
  finish: ->
    setStatus 'done'
    JobQueue.update {waitingOn: @jobQueueId}, {$pull: {waitingOn: @jobQueueId}}
  
  @inputSchema: {}
  
  @outputSchema: {}

class ThumbnailProcessor extends Processor
  process: ->
    ###TODO some thoughts: do we want this to determine automatically how to make the thumbnail?
    # I would think so. I like the idea of simply running this and it can determine what kind of
    # thumbnail to make. However, that also implies that we need to either:
    #   a) trust the extension of the file, or
    #   b) run tika and decide what kind of file it is
    # In the interest of modularization, I don't like the idea of making Tika a necessary component
    # of this processor. I feel like they should all be independent. However, I'd be okay if we
    # guarantee that Tika is run on all files first, so we know that metadata will be there (In thi
    # case I guess 'there' is in a database somewhere (or fileserver?))
    #
    # Anyhoo, for now I'm going to have this only work for images. Another possibility might be to
    # have seperate processors for each file type, and a 'smart' version of the processor that will
    # take in a file, run tika, and decide how to best proceed. I kind of like that idea, and think
    # it would could be expanded to work well with other processors
    ###
    Future = Npm.require 'fibers/future'
    im = Meteor.require 'imagemagick'
    f = @settings.file.name
    console.log "here I am: " + process.cwd() #TODO doesn't print where i am
    md5 = 'this_is_not_an_md5' #TODO does this need an md5?
    thumbnailFuture = new Future()
    im.convert ['uploads/' + f, '-resize', '64x64', './uploads/thumbnail_'+f+'.jpg'], -> #TODO don't use f
      console.log @
      console.log arguments
      console.log 'generated thumbnail for ' + f
      thumbnailFuture.return {}
    thumbnailFuture.wait()
    console.log 'finished!'
    #@setStatus 'done'
    @finish

  @outputSchema: new SimpleSchema
    file:
      type: Object
    'file.name':
      type: String
    'file.type':
      type: String
      allowedValues: ["jpg"]
    'file.size':
      type: Number


class UploadProcessor extends Processor
  process: ->
    console.log 'This is our current fiber (from UploadProcessor): '
    console.log Fiber.current
    #Save to disk -- will append as new sections come in
    path = cleanPath path 
    fs = Npm.require 'fs'
    name = cleanName (@settings.file.name || 'file') 
    encoding = encoding || 'binary'
    chroot = Meteor.chroot || 'uploads'
    path = chroot + (if path then '/' + path + '/' else '/')
    
    #TODO Add file existance checks, etc...
    console.log 'Writing ' + path + @settings.file.name
    currentUploadsKey = JSON.stringify(@settings.file)
    mf = CurrentUploads[currentUploadsKey]

    if mf? #why this check? Because in the line above, we grab the mf from current uploads
      ###if mf.size is mf.end
        #@setStatus 'done'
        console.log 'about to call schedule job'
        ScheduleJob 'VideoTranscodeProcessor', [], [], @settings 
        @finish
      #mf.save path###
 
      #do while?
      while mf.end <= mf.size #last chunk's end property will be equal to size, right?
        console.log 'Not done, saving chunk.'
        mf.save path
        console.log 'Chunk saved. Waiting on next chunk...'
        #Get the new future and wait on it. It will return when their is a new meteor file chunk
        CurrentUploads[currentUploadsKey]['future'].wait()
        mf = CurrentUploads[currentUploadsKey]['meteorFile'];

      console.log 'Okay, done. mf.size='+mf.size+' mf.end='+mf.end
      console.log 'Written! Scheduling VideoTranscoderProcessor'
      ScheduleJob 'VideoTranscodeProcessor', [], [], @settings 

    return _.pick @settings, 'file'

  @outputSchema: new SimpleSchema
    file:
      type: Object
    'file.name':
      type: String
    'file.type':
      type: String
    'file.size':
      type: Number

class Md5FileProcessor extends Processor
  process: ->
    fs = Npm.require 'fs'
    crypto = Npm.require 'crypto'

    console.log 'computing md5'

    s = fs.ReadStream @sourcefile
    md5sum = crypto.createHash 'md5'
    Future = Npm.require 'fibers/future'

    future = new Future()

    s.on 'data', (d) ->
      md5sum.update(d)
    s.on 'end', ->
      md5 = md5sum.digest('hex')
      future.return md5
    md5 = future.wait()
    console.log 'md5 of ' + @sourcefile + ' is ' + md5
    return md5

class Tika extends Processor
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'

    f = @sourcefile

    tikaFuture = new Future() 

    tika = spawn('java', ['-jar', 'tika-app-1.4.jar', '-j', f])
    tika.stdout.parse_text = ''
    tika.stdout.on 'data', (data) ->
      @parse_text += data
    tika.on 'close', (code, signal) ->
      try
        metadata = JSON.parse @stdout.parse_text
        tikaFuture.return metadata
      catch e
        console.log 'Error parsing metadata for ' + f
        console.log e
        tikaFuture.return {}

    metadata = tikaFuture.wait()

    console.log 'Got metadata for ' + f + ': ' + metadata['Content-Type']
    console.log 'Waited for tika process to finish'
    console.log metadata
    metadata

class VideoTranscodeProcessor extends Processor
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'
    
    ffmpegFuture = new Future() 
    fileName = @settings.file.name
    ffmpeg = spawn 'ffmpeg', ['-i', fileName, fileName.substr(0, fileName.indexOf('.'))  + '.avi']
    ffmpeg.on 'close', (code, signal) ->
      try
        console.log 'Video transcoding successful!'
        ffmpegFuture.return {}
      catch e
        console.log 'Error during video transcoding.'
    ffmpeg.wait()
    console.log 'Finished with this VideoTranscodeProcessor!'
    @setStatus 'done'
    @finish

#TODO don't all of this instiate an instance of the processors? Why aren't doesn't this fail since
#we don't provide each processor a source file? what exactly does accessing one of these mean?
(exports ? @).Processors =
  Md5: Md5FileProcessor
  Tika: Tika
  Upload: UploadProcessor

(exports ? this).ThumbnailProcessor = ThumbnailProcessor
(exports ? this).UploadProcessor = UploadProcessor
(exports ? this).VideoTranscodeProcessor = VideoTranscodeProcessor
#helpers
cleanPath = (str) ->
  if str
    return str.replace(/\.\./g,'').replace(/\/+/g,'').
      replace(/^\/+/,'').replace(/\/+$/,'')

cleanName = (str) ->
  return str.replace(/\.\./g,'').replace(/\//g,'')

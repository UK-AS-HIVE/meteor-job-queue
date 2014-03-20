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
  for pipelineIndex in [0..pipeline.length - 1]
    currentPipePartIds = []
    for job in pipePart
      currentPipePartIds.push ScheduleJob job.processorType, parents, job.settings
    parents = currentPipePartIds
      
(exports ? @).ScheduleJob = (processorType, parentJobs, settings) ->
  JobQueue.insert
    processor: processorType
    parentJobs: parentJobs
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
    md5 = 'this_is_not_an_md5' #TODO might not have an md5
    thumbnailFuture = new Future()
    im.convert [f, '-resize', '64x64', '../overlay_thumbnails/'+md5+'.jpg'], ->
      console.log 'generated thumbnail for ' + f
      thumbnailFuture.return {}
    thumbnailFuture.wait()
    console.log 'finished!'
    #return anything?

class UploadProcessor extends Processor
  process: ->
    #Save to disk -- will append as new sections come in
    path = cleanPath path 
    fs = Npm.require 'fs'
    name = cleanName (@settings.file.name || 'file') 
    encoding = encoding || 'binary'
    chroot = Meteor.chroot || 'uploads'
    path = chroot + (if path then '/' + path + '/' else '/');
    
    #TODO Add file existance checks, etc...
    console.log 'Writing ' + path + @settings.file.name

    mf = CurrentUploads[JSON.stringify(@settings.file)]

    if mf?
      if mf.size is mf.end
        @setStatus 'done'

      mf.save path
      console.log 'Written!'

    ScheduleJob 'ThumbnailProcessor', [@_id], @settings

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
    tikaComplete = tikaFuture.resolver()

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


#TODO don't all of this instiate an instance of the processors? Why aren't doesn't this fail since
#we don't provide each processor a source file? what exactly does accessing one of these mean?
(exports ? @).Processors =
  Md5: Md5FileProcessor
  Tika: Tika
  Upload: UploadProcessor

(exports ? this).ThumbnailProcessor = ThumbnailProcessor
(exports ? this).UploadProcessor = UploadProcessor
 
#helpers
cleanPath = (str) ->
  if str
    return str.replace(/\.\./g,'').replace(/\/+/g,'').
      replace(/^\/+/,'').replace(/\/+$/,'')

cleanName = (str) ->
  return str.replace(/\.\./g,'').replace(/\//g,'')

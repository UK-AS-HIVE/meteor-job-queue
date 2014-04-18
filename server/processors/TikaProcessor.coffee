class Processors.TikaProcessor extends Processors.Processor
  process: ->
    fs = Npm.require('fs')
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'

    f = @settings.file.name
    tikaFuture = new Future() 
    
    tika = spawn('java', ['-jar', 'tika-app-1.5.jar', '-j', './uploads/' + f])
    parse_text = ''
    tika.stdout.on 'data', (data) ->
      parse_text += data

    tika.stderr.on 'data', (data) ->
      console.log "STDERR: " + data
 
    tika.on 'close', (code, signal) ->
      try
        metadata = JSON.parse parse_text
        tikaFuture.return metadata
      catch e
        #TODO set the status to error NOTE TO FUTURE SELF: Tika error? maybe you were doing
        #video transcoding while this was happening. But this happens on the wmv...
        console.log 'Error parsing metadata for ' + f
        console.log e
        tikaFuture.return 1

    metadata = tikaFuture.wait()
    if metadata is 1
      @setStatus 'error'
    else
      console.log 'Got metadata for ' + f + ': ' + metadata['Content-Type']
     
      @finish()

    return {metadata: metadata} #do we want to return this no matter what?

  #TODO is this a safe output schema?
  @outputSchema: new SimpleSchema
    metadata:
      type: Object
    'metadata.Content-Type':
      type: String
    'metadata.resourceName':
      type: String
    'metadata.Content-Length':
      type: Number

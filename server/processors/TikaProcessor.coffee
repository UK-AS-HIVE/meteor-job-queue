class @TikaProcessor extends @Processor
  process: ->
    spawn = Npm.require('child_process').spawn
    Future = Npm.require 'fibers/future'

    f = @settings.file.name

    tikaFuture = new Future() 

    tika = spawn('java', ['-jar', 'tika-app-1.5.jar', '-j', './uploads/' + f])
    parse_text = ''
    tika.stdout.on 'data', (data) ->
      parse_text += data
 
    tika.on 'close', (code, signal) ->
      try
        metadata = JSON.parse parse_text
        tikaFuture.return metadata
      catch e
        console.log 'Error parsing metadata for ' + f
        console.log e
        tikaFuture.return {}

    metadata = tikaFuture.wait()

    console.log 'Got metadata for ' + f + ': ' + metadata['Content-Type']
   
    @finish()
    return {metadata: metadata}

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

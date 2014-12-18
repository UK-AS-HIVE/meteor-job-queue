class @Processors.ThumbnailProcessor extends @Processors.Processor
  process: ->
    #I took out a lot of the previous thoughts. ImageMagick can identify videos and try to make thumbnails, but it'll make thumbnails for every frame if a frame isn't specified.
    #I still like the idea of a smart processor? But that's a later disucssion. 
    #It takes forever for IM to identify whether or not it's a video, so we just give it a frame no matter what. 
    @setStatus 'processing'
    Future = Npm.require 'fibers/future'
    gm = Npm.require 'gm'

    f = @settings.file.name
    t = f.substr 0, f.lastIndexOf('.') || f;
    convertFuture = new Future()
    thumbnailFuture = new Future()
    
    gm f+'[0]' #Just use the first frame, in case we're getting passed an animated gif or video.
    .options({imageMagick: true})
    .resize(64,64)
    .write t + '_thumbnail.jpg', (err) ->
      if err 
        console.log("Err in writing thumbnail: " + err)
        convertFuture.return(false)
      else
        convertFuture.return(true)
    
    file = {} #Temp object to store until we can move back into the parent settings. This is hacky because I'm bad at js
    if convertFuture.wait()
      gm t + '_thumbnail.jpg'
      .options({imageMagick: true})
      .identify (err, data) ->
        file.format = data.format
        file.name = data.path
        file.size = data.Filesize
        thumbnailFuture.return(file)

    @finish()
    @settings.file = thumbnailFuture.wait()
    return @settings

  @outputSchema: new SimpleSchema
    'file':
      type: Object
    'file.name':
      type: String
    'file.format':
      type: String
      allowedValues: ["JPEG"]
    'file.size':
      type: String

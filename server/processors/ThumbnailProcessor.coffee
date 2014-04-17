class Processors.ThumbnailProcessor extends Processors.Processor
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
    
    @finish()
    return _.pick @settings, file

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

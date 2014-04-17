class Processors.UploadProcessor extends Processors.Processor
  process: ->
    #Save to disk -- will append as new sections come in
    path = cleanPath path 
    fs = Npm.require 'fs'
    name = cleanName (@settings.file.name || 'file') 
    encoding = encoding || 'binary'
    chroot = Meteor.chroot || 'uploads'
    path = chroot + (if path then '/' + path + '/' else '/')
    
    #TODO Add file existance checks, etc...
    console.log 'Writing ' + path + @settings.file.name
    currentUploadsKey = JSON.stringify(_.pick(@settings.file, 'name', 'type', 'size'))
    mf = CurrentUploads[currentUploadsKey]['meteorFile']

    if mf? #why this check? Because in the line above, we grab the mf from current uploads
       while mf.end < mf.size #last chunk's end property will be equal to size, right? right, we'll 
                              #save that chunk after the loop.
                              #TODO this implies we never wait on the last future, which is true.
                              #     worth avoiding trying to instantiate it?
        console.log 'Not done, saving chunk.'
        mf.save path
        console.log 'Chunk saved. Waiting on next chunk...'
        @setStatus mf.uploadProgress + '%'  
        #Get the new future and wait on it. It will return when their is a new meteor file chunk
        CurrentUploads[currentUploadsKey]['future'].wait()
        mf = CurrentUploads[currentUploadsKey]['meteorFile']

      console.log 'Saving last chunk!'
      mf.save path
      
      console.log 'Scheduling VideoTranscoderProcessor, Tikas, and Md5Gens'

      vidSettings = @settings #TODO this works by reference, I wanted to copy. Apparently very i
                              #difficult
      vidSettings['targetType'] = 'blah' 
      ScheduleJob 'VideoTranscodeProcessor', [], [], vidSettings 
      ScheduleJob 'TikaProcessor', [], [], @settings
      ScheduleJob 'Md5GenProcessor', [], [], @settings

    @finish()  
    delete CurrentUploads[currentUploadsKey]    
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

#Helpers
cleanPath = (str) ->
  if str
    return str.replace(/\.\./g,'').replace(/\/+/g,'').
      replace(/^\/+/,'').replace(/\/+$/,'')

cleanName = (str) ->
  return str.replace(/\.\./g,'').replace(/\//g,'')

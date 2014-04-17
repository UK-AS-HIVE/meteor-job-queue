class Processors.Md5GenProcessor extends Processors.Processor
  process: ->
    fs = Npm.require 'fs'
    crypto = Npm.require 'crypto'
    f = @settings.file.name

    console.log 'computing md5'

    s = fs.ReadStream './uploads/' + f
    md5sum = crypto.createHash 'md5'
    Future = Npm.require 'fibers/future'

    future = new Future()

    s.on 'data', (d) ->
      md5sum.update(d)
    s.on 'end', ->
      md5 = md5sum.digest('hex')
      future.return md5
    md5 = future.wait()
    console.log 'md5 of ' + f + ' is ' + md5
    @finish()
    return {md5: md5}

  @outputSchema: new SimpleSchema
    md5:
      type: String
      regEx: /[a-f0-9]{32}/ #TODO have Noah check this out
      min: 32
      max: 32

#Processors.Md5GenProcessor = Md5GenProcessor

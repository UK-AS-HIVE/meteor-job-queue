doc = document.documentElement
doc.ondragover = (e) ->
  @className = 'hover'
  e.preventDefault()
  false

doc.ondragend = ->
  @className = ''
  false

doc.ondrop = (e) ->
  e.preventDefault()
  @className = ''
  console.log e.dataTransfer.files[0]
  
  for item in e.dataTransfer.items
    entry = item.webkitGetAsEntry()
    if entry
      if entry.isFile
        console.log entry
        files = e.dataTransfer.files
        console.log files

        for file in files
          MeteorFile.upload file, 'meteorFileUpload', {}, ->
            console.log 'callback meteorFileUpload'
            console.log arguments

      else if entry.isDirectory
        console.log entry
        traverse = (item, path) ->
          console.log 'traversing ' + path
          path = path || ''
          if item.isFile
            console.log 'file '
            console.log item
            item.file (file) ->
              console.log 'uploading file starting at ' + new Date()
              MeteorFile.upload file, 'meteorFileUpload', {}, ->
                console.log 'done uploading file at ' + new Date()
          else if item.isDirectory
            console.log 'directory '
            console.log item
            item.createReader().readEntries (entries) ->
              traverse entry, path + item.name + '/' for entry in entries
        traverse entry, ''

  false

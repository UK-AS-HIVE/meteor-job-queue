fileUpload = (item) ->
  item.file (file) ->
    console.log 'uploading file starting at ' + new Date()
    MeteorFile.upload file, 'meteorFileUpload', {}, ->
      console.log 'done uploading file at ' + new Date()


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
        fileUpload entry
      else if entry.isDirectory
        console.log entry
        traverse = (item, path) -> 
          path = path || ''
          if item.isFile
            fileUpload item
          else if item.isDirectory
            item.createReader().readEntries (entries) ->
              traverse entry, path + item.name + '/' for entry in entries
        traverse entry, ''

  return false

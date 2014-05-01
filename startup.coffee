Meteor.startup () ->
  cwd = process.cwd()
  if cwd.indexOf '.meteor' is not -1
    console.log 'Running unbundled, moving out of .meteor dir'
    process.chdir '../../../../..'

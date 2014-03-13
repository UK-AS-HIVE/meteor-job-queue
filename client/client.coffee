Handlebars.registerHelper 'arrayify', (obj) ->
  {name:key, value: val} for own key, val of obj

Template.queue.helpers
  queuedItems: -> JobQueue.find {}, {sort: {submitTime: -1}}
  fromNow: (date) ->
    d = Deps.currentComputation

    setTimeout ->
      d.invalidate()
    , 5000

    moment(date).fromNow()

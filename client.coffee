_= lodash
_.extend Settings, 
  get: ->
    _collection.findOne
      type: 'settings'
  subscribe: ->
    args= [Settings.collection_name]
    if arguments.length
      args.push arguments ...
    Meteor.subscribe args...
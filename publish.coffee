_=lodash


_.extend Settings,
  check_setting_set_permission:(key,context,context_key, value)->
    return true
  # set to function(key,context,context_key, value) to select the collection from which a context setting is read/written 
  setting_collection_selector:null
  # set to function(key,context,context_key, value) to insert the setting key into context
  # permissions are alredy checked!
  insert_setting:null


class SettingPublisher

  constructor: (@opts)->
    if @opts.settings_cursor_generator
      @settings_cursor_generator=@opts.settings_cursor_generator
    @pub_handler=@pub_handler
    self=this
    @setting_to_ctx={}
  run:()->
    @startup=true
    @cursor.observe this
    @startup=false
    @start_compiler()
  added: (doc)=>
    @setting_to_ctx[doc.name]?=doc
    doc.resolved_contexts= doc.contexts.map ClientId.ctx_key.bind ClientId
    @restart_compiler()
  changed: (doc, old)=> 
    @setting_to_ctx[doc.name]=doc
    doc.resolved_contexts= doc.contexts.map ClientId.ctx_key.bind ClientId
    @restart_compiler()
  removed: (old)=>
    delete @setting_to_ctx[doc.name]
    restart_compiler()
  start_compiler: (published)->
    @compiler= new SettingsCompiler @setting_to_ctx, published, @opts
  restart_compiler:->
    published= @compiler.stop()
    @start_compiler @setting_to_ctx, published,
      cursors= @settings_cursors_generator()
  settings_cursors_generator: ->
    ret = @opts.collection.find 
      type: 'setting:context'
      _context:
        $in: _.flatten _.map @setting_to_ctx (ctx, setting_name)->
          return ctx.resolved_contexts
    return [ret]
    
class settingsCompiler

  constructor: (@setting_to_ctx, @published, @opts)->
    @pub_stack={}
    _.each @setting_to_ctx, (ctx, setting)=>
      if ctx.contexts?
        len= ctx.contexts.length
      else
        len= 0
      ## last element is default pub_stack.length - ctx.contexts.length + 1
      len= len+1
      @pub_stack[setting]= new Array(len)
      @pub_stack[setting][len-1]=ctx.default # Might be undefined which is OK
    @_change={}
    @publish_collection_name = opts.publish_collection_name
    @publish_collection_name ?= 'settings'
  run:()->
    @cursor_handlers?=[]
    for cursor in @opts.cursors
      @cursor_handlers.push cursor.observeChanges this
  stop:()->
    hs=@cursor_handlers
    @cursor_handlers=null
    hs.forEach (h)->x.stop()
  apply_change:()->
    if @published?
      @opts.pub_handler.changed @publish_collection_name, @published._id,  @_change
      _.extend @published, @_change
    else
      @published = _.extend { _id:Random.id() }, @_change
      @opts.publish_handler.added @publish_collection_name, @published._id, @change
  
  _update_pub_stack: (id,doc)->
    dirty_settings=[]
    _.each _.omit(doc, ['_id', '_context']) , (val, setting)=>
      if (def = @setting_to_ctx[setting])?
        def.resolved_contexts.forEach (ctx, idx)=>
          if ctx == doc._context
            unless _.isEqual  @pub_stack[setting][idx],val
              @pub_stack[setting][idx]=val
              dirty_settings.push setting
  added:(id,doc)=>
    ret= {}
    
    dirty_settings= @_update_pub_stack(id,doc)
    #updates the pubstack

    dirty_settings.forEach (setting)=>
      val = _.find @pub_stack[setting] (val,idx)-> return not _.isUndefined val
      unless val == @published?[setting]
        @_change[setting]=val 
    @apply_change()
  changed: (id,doc)=>
    #the same
    @added id,doc 
  removed:(doc) =>
    @added id, doc



Meteor.publish Settings.collection_name, ContextId.inPublishContext ( app_name='client')->
  pub= this
  
  setting_publisher= new SettingPublisher
    collection: Settings._collection
    settings_def_cursor= Settings._collection.find
      type:'setting:definition'

  @onStop ->
    setting_publisher
  setting_def.run()
Meteor.methods 'set_setting', (key, value, context)->
  context_key= ClientId.ctx_key context
  
  setting_def = Settings._collection.findOne
    type:'setting:definition'
    name:key
  unless setting_def
    throw new Meteor.Error 'setting-none', "Setting #{key} is not defined"
  if setting_def.fixed?
    throw new Meteor.Error 'setting-unsettable', "setting #{key} may not be set by client" 
  context?='default'
  if setting_def.contexts? and setting_def.contexts.length
    context = _.find setting_def.contexts, context
    unless context?
      throw new Meteor.Error 'setting-no-such-context', "Context #{arguments[2] or 'default'} is not allowed for this setting"
  else  if context != 'default'
    throw new Meteor.Error 'setting-no-such-context', "Context #{arguments[2] or 'default'} is not allowed for this setting"
  context_key= ContextId.ctx_key(context)
  
  unless Settings.check_setting_set_permission(key,context,context_key, value)
    throw new Meteor.Error 'setting-permission-denied', "Permission denied to set setting #{key} to #{value} in context #{context}"
  if Settings.insert_setting?
    Settings.insert_setting(key,context,context_key, value)
  else 
    if Settings.setting_collection_selector?
      collection = Settings.setting_collection_selector(key, context, context_key)
    else
      collection= Settings._collection
    doc= collection.findOne {_context:context_key}
    if doc?
      collection.update doc._id,
        $set: _.object [[key,value]]
    else
      collection.insert 
        type:'setting:context'
        _context: context
        fields: _.object [[key,value]]













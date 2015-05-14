_=lodash
multi_ready = (counter,ready_func)->
  ->
    counter--
    unless counter
      ready_func()
Tinytest.add 'empty test', (test)->
  test.isTrue true

Tinytest.addAsync 'settings subscription', (test, ready)->
  Settings.subscribe
    onReady:->
      ready()


Tinytest.addSettingTest = (name, key, opts)->
  Tinytest.addAsync name, (test, ready)->
    if 'value' of opts
      value= opts.value
    else
      value= Random.id()
    ready= multi_ready(2,ready)
    Meteor.call  'set_setting', key , value, (error,result)->
      opts.rpc_result_test?(test,error,result)
      ready()
      if error
        ready()
      else
        initial_settings= Settings.settings()
        autorun= Tracker.autorun (c)->
          settings= Settings.settings()
          if autorun_continue?
            unless autorun_continue(test,initial_settings,settings, value)
              c.stop()
          else if settings[key]==value
            c.stop()
          
          @onInvalidate ->
            if c.stopped
              ready()
        timeout_id= Meteor.setTimeOut ->
            test.isFalse true , "setter waiting timed out"
            autorun.stop()
          ,
            1000
        ready()

Tinytest.addSettingTest  'add browser setting', 'def_ctx_no_default',
  rpc_result_test: (test, error,result)->
    test.isFalse error, "Valid call, but caught Error #{error}"
  autorun_continue:(test,initial_settings,current_settings, set_value)->
    unless _.isEqual initial_settings,current_settings 
      test.equal current_settings.def_ctx_no_default, set_value ,"Different value outcome"
      return false
    else
      return true




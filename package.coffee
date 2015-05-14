Package.describe
  name:"pba:bringme-settings"
  description: "bringme reactive settings using context-id"


Package.on_use (api)->
  client= 'client'
  server= 'server'
  both= [client, server]

  both_f= ['common.coffee'] 
  client_f= ['client.coffee']
  server_f= ['publish.coffee'] 
 
  api.use [
    'coffeescript'
    'pba:context-id'
    'alethes:lodash@0.7.1'
    ], both


  api.add_files both_f, both
  api.add_files client_f, client
  api.add_files server_f, server
  
  return api.export 'Settings' ;
Package.on_test (api)->
  client= 'client'
  server= 'server'
  both= [client, server]

  api.use [
      'tinytest' 
      'coffeescript'
      'pba:bringme-settings'
      'alethes:lodash@0.7.1'
      'random'
    ]
  api.add_files ['test/client.coffee','test/server.coffee'], client
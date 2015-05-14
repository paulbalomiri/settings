_= lodash
Settings._collection.remove({})
users:['userA', 'userB']
def = 
  type:'setting:definition'
i=0
fixtures=
  defs:
    ###
    Setting definitions
    ###
    def_ctx_no_default: def 
    def_ctx_with_default: _.extend {},def,
      default:'default-value' + i++
    one_ctx_no_default:_.extend {},def,
      contexts: 'browser_session'
    one_ctx_with_default:_.extend {},def,
      contexts: 'browser_session'
      default: 'default-value'+ i++
    multi_ctx_no_default: _.extend {},def,
      contexts:[
          'browser_session'
          'browser'
          'default'
        ]
    multi_ctx_no_default: _.extend {},def,
      contexts:[
          'user_browser_session'
          'user_browser'
          'default'
        ]
_.each fixtures.defs, (val, id)->
  Settings._collection.insert _.extend {_id:id, name:id}, val





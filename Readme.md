
# Settings collection with permissions

The `pba:settings` package grabs settings as defined by documents of type 'setting:definition'

## `Settings` export (_client_)
The Package exports a Settings object
* `Settings.subscribe()` Wrapper around the `Meteor.subscribe `Settings.collection_name`
* `Settings.get([key])`: get the Settings object, or the `key` property of that object (reactive).
* `Settings.set(key,[val],[context])` set the Key `key` to [`value`] val
  * if `val` is ommited or set to undefined than key is unset 
  * if `context` is supplied it must be one of the values from the corresponding *definition object* `.contexts` values, else `'default'` is assumed
## Published setting collection (_client_)
The clientside collection Settings._collection contains a single clientside entry: the compiled settings object.
The settings object can be easily and *reactively* be accessed using `Settings.get()`

## Setting a contexted `key` (_client_)
  `Settings.set('my_key', 'my_val', "browser")` sets the browser specific key if all these are trueish
  * a correspanding *settings definition object*(**SDO**) exists in the server collection
  * The **SDO** is not `.fixed`
  * The **SDO** has `"browser"` as one of the items in the  `.contexts` property value
  * The `Settings.check_setting_set_permission` returns a truish value (and does not throw)
  
## Setting definition objects (_server_)
These objects are entries -one per setting- of the `Settings._collection`
collection.

The *setting definition object* may be either:
```
  type: 'setting:definition'
  name:  setting name
  fixed: value
```
or:
``` 
  type: 'setting:definition'
  name: setting name
  default: optional default value for the setting
  contexts: optional `['context1','context2', 'context3' ]` ... or a single context string
```
 * The `type` must be set, as other objects may also live in the same collection
 * If a `.fixed` field exists `.default` and `contexts` may not also exist
 * If `.contexts` is ommited then context `default` is assumed
 * A string value for `.contexts` is equivalent to a single item list ( `'maycontext'` is eqivalent to `['mycontext']` )
 * Any value in `.contexts` must be a key of `ContextId.scope`, like
    * `browser`, `browser_session`, `user_browser` , e.t.c
    * See [Package `pba:context-id` ](https://github.com/paulbalomiri/meteor-context-id/) for details
## Setting value objects (server)
`'settings:context'` types objects have the fields:
* `type:'settings:context'`
*  `context_key:` *`context_id`* which is the result of `ContextId.ctx_key('browser')` for the browser context
*  `fields`: An object containing the setting properties specific for this `context_key` (as in context above)

## Resolution Order

## Configuration [Advanced] (_server_)
* `Settings.check_setting_set_permission (key,context,context_key, value)`
  * By default returns just `true`
  * Security (dis-)considerations (TODO: Reference this to `pba:context-id` package docs)
    * Security whie this is ok, as the user contexts are guarded by whatever metod you use for authentication
    * Insecure contexts (like `'browser'` as opposed to `'user_browser'`) are Random-secure, meaning that the random browser id could be set by a malicious client and override another users` values
    * the userid is taken serverside, so any context `/user_.*/` context is securely accessible only by the authenticated user
  * Implementations must return a truty value for any operation to be done.
  * Reject either by returning a *falsey* value or by throwing a Meteor.Error (See meteor docs for throwing in RPC method)
* `Settings.setting_collection_selector(key, context, context_key)`
  * return the collection where to insert the `key` & `value`
  * This method makes it possible to pug e.g. each `context` into it's own collection, or any other mapping
* `Settings.insert_setting(key,context,context_key, value)`
  * Insert the context yourself (e.g. in the user.profile)
  * make sure to also implement `Settings.get_setting` if you intend to do this
  * if this method is implemented `Settings.setting_collection_selector(key, context, context_key)` is not used for inserting keys
## Resolution order
The keys are read for each context in the **SDO**'s `.contexts` list.
The contexts are evaluated in the same way underscore/lodash resolves using the `_.defaults` function
**Examples:**
  * Ex1: Overriding specific browser for specific user
    * `sdo.contexts==['user_browser', 'browser']`
    * `sdo.default== ''red'`
    * setting in `'browser'` context: `'green'`
    * setting in `user_browser` context: `'red'`
    * **``red``** will be sent to the client
  * Ex2: same as Ex1 but no `user_browser` context set (or value in that context missing)
    * `sdo.contexts==['user_browser', 'browser']`
    * `sdo.default== ''red'`
    * setting in `'browser'` context: `'green'`
    * setting in `user_browser` context: `undefined`/*not set*
    * **``green``** will be sent to the client
  * Overriding specific browser for specific user
    * `sdo.contexts==['user_browser', 'browser']`
    * `sdo.default== ''red'`
    * No specific context set
    * **`'red'`** wins 





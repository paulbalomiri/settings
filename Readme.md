
# Settings collection with permissions

The *Settings* pacl grabs settings as defined by documents of type 'setting:definition'

Definition objects may be either:
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
 * If a `.fixed` field exists `.default` and `contexts` may not also exist
 * If `.contexts` is ommited then context `default` is assumed
 * A string value for `.contexts` is equivalent to a single item list ( `'maycontext'` is eqivalent to `['mycontext']` )




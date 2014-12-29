{splitKeyPath} = require 'key-path-helpers'

# Public: Check if `value` is an {Object}
isPlainObject = (value) ->
  value?.constructor is Object

# Public: Get an object's value for a given key-path, and also an indication
# of whether or not the object would affect the key-path in a deep-merge.
#
# Returns an {Array} with two elements:
# * `value` The value at the given key-path, or `undefined` if there isn't one.
# * `hasValue` A {Boolean} value:
#   * `true` if `object` would override the given key-path if deep-merged
#      into another {Object} (see {::deepDefaults}). This means either `object`
#      has a value for the given key-path, `object` is not an {Object}, or one
#      of `object`'s children on the key-path is not an {Object}.
#   * `false` if the object would not alter the given key-path if deep-merged
#     into another {Object}.
checkValueAtKeyPath = (object, keyPath) ->
  for key in splitKeyPath(keyPath)
    if isPlainObject(object)
      if object.hasOwnProperty(key)
        object = object[key]
      else
        return [undefined, false]
    else
      return [undefined, true]
  [object, true]

# Public: Fill in missing values in `target` with those from `defaults`,
# recursing into any nested {Objects}
deepDefaults =  (target, defaults) ->
  if isPlainObject(target) and isPlainObject(defaults)
    for key in Object.keys(defaults)
      if target.hasOwnProperty(key)
        deepDefaults(target[key], defaults[key])
      else
        target[key] = defaults[key]
  return

deepClone = (value) ->
  if Array.isArray(value)
    value.map (element) -> deepClone(element)
  else if isPlainObject(value)
    result = {}
    for key in Object.keys(value)
      result[key] = deepClone(value[key])
    result
  else
    value

module.exports = {
  isPlainObject, checkValueAtKeyPath, deepClone, deepDefaults
}

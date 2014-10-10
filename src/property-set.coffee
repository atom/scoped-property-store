{deepExtend, hasKeyPath, valueForKeyPath} = require 'underscore-plus'

module.exports =
class PropertySet
  constructor: (@source, @selector, @properties) ->
    @name = @source # Supports deprecated usage

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

  merge: (other) ->
    new PropertySet(@source, @selector, deepExtend(@properties, other.properties))

  has: (keyPath) ->
    hasKeyPath(@properties, keyPath)

  get: (keyPath) ->
    valueForKeyPath(@properties, keyPath)

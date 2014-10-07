{deepExtend, hasKeyPath, valueForKeyPath} = require 'underscore-plus'

module.exports =
class PropertySet
  constructor: (@source, @selector, @properties) ->
    @name = @source # Supports deprecated usage

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

  selectorsEqual: (other) ->
    @selector.selector is other.selector.selector

  merge: (other) ->
    new PropertySet(@source, @selector, deepExtend(other.properties, @properties))

  has: (keyPath) ->
    hasKeyPath(@properties, keyPath)

  get: (keyPath) ->
    valueForKeyPath(@properties, keyPath)

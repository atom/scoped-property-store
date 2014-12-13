{deepExtend} = require 'underscore-plus'
{hasKeyPath, getValueAtKeyPath} = require 'key-path-helpers'

module.exports =
class PropertySet
  constructor: (@source, @selector, @properties) ->
    @name = @source # Supports deprecated usage

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

  merge: (other) ->
    new PropertySet(@source, @selector, deepExtend(other.properties, @properties))

  has: (keyPath) ->
    hasKeyPath(@properties, keyPath)

  get: (keyPath) ->
    getValueAtKeyPath(@properties, keyPath)

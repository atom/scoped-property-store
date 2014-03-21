{hasKeyPath, valueForKeyPath} = require 'underscore-plus'

module.exports =
class PropertySet
  constructor: (@selector, @properties) ->

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

  has: (keyPath) ->
    hasKeyPath(@properties, keyPath)

  get: (keyPath) ->
    valueForKeyPath(@properties, keyPath)

{hasKeyPath, valueForKeyPath} = require 'underscore-plus'

module.exports =
class PropertySet
  constructor: (@source, @selector, @properties) ->

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

  has: (keyPath) ->
    hasKeyPath(@properties, keyPath)

  hasAll: (keyPaths) ->
    for keyPath in keyPaths
      return false unless hasKeyPath(@properties, keyPath)
    true

  get: (keyPath) ->
    valueForKeyPath(@properties, keyPath)

  getMultiple: (keyPaths) ->
    for keyPath in keyPaths
      valueForKeyPath(@properties, keyPath)

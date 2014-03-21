module.exports =
class PropertySet
  constructor: (@selector, @properties) ->

  matches: (scope) ->
    @selector.matches(scope)

  compare: (other) ->
    @selector.compare(other.selector)

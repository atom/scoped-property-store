slick = require 'slick'
Selector = require './selector'
PropertySet = require './property-set'

module.exports =
class ScopedPropertyStore
  constructor: ->
    @propertySets = []

  addProperties: (source, propertiesBySelector) ->
    for selectorSource, properties of propertiesBySelector
      for selector in Selector.create(selectorSource)
        @propertySets.push(new PropertySet(selector, properties))

  get: (scopeChain, keyPath) ->
    candidateSets = @propertySets.filter (set) -> set.properties[keyPath]?

    return unless candidateSets.length > 0

    scopeChain = (scope for scope in slick.parse(scopeChain)[0])
    while scopeChain.length > 0
      matchingSets =
        candidateSets
          .filter (set) -> set.matches(scopeChain)
          .sort (a, b) -> a.compare(b)

      return matchingSets[0].properties[keyPath] if matchingSets.length > 0
      scopeChain.pop()
    undefined

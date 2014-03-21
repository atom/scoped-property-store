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
    candidateSets = @propertySets.filter (set) -> set.has(keyPath)

    return unless candidateSets.length > 0

    scopeChain = (scope for scope in slick.parse(scopeChain)[0])
    while scopeChain.length > 0
      matchingSets =
        candidateSets
          .filter (set) -> set.matches(scopeChain)
          .sort (a, b) -> a.compare(b)

      if matchingSets.length > 0
        return matchingSets[0].get(keyPath)
      else
        scopeChain.pop()
    undefined

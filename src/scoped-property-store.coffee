slick = require 'slick'
Selector = require './selector'
PropertySet = require './property-set'

# Public:
module.exports =
class ScopedPropertyStore
  constructor: ->
    @propertySets = []

  # Public: Add scoped properties to be queried with {::get}
  #
  # source - A string describing these properties to allow them to be removed
  #   later.
  # propertiesBySelector - An {Object} containing CSS-selectors mapping to
  #   {Objects} containing properties. For example: `{'.foo .bar': {x: 1, y: 2}`
  addProperties: (source, propertiesBySelector) ->
    for selectorSource, properties of propertiesBySelector
      for selector in Selector.create(selectorSource)
        @propertySets.push(new PropertySet(source, selector, properties))

  # Public: Remove scoped properties previously added with {::addProperties}
  #
  # source - The source (previously provided to to {::addProperties}) of the
  #   properties to remove.
  removeProperties: (source) ->
    @propertySets = @propertySets.filter (set) -> set.source isnt source

  # Public: Get the value of a previously stored key-path in a given scope.
  #
  # scopeChain - This describes a location in the document. It uses the same
  #   syntax as selectors, with each space-separated component representing one
  #   element.
  # keyPath - A `.` separated string of keys to traverse in the properties.
  #
  # Returns the property value or `undefined` if none is found.
  get: (scopeChain, keyPath) ->
    result = @getMultiple(scopeChain, keyPath)
    if result.length is 1
      result[0]
    else
      undefined

  # Public: Get the values of multiple previously stored key-paths in a given
  # scope.
  #
  # The properties must all belong to the same property set, meaning they were
  # siblings under the same scope selector in a previous call to
  # {::addProperties}. If no property set can be found containing all the given
  # properties, an empty array is returned.
  #
  # Returns an {Array}.
  getMultiple: (scopeChain, keyPaths...) ->
    candidateSets = @propertySets.filter (set) -> set.hasAll(keyPaths)

    return [] unless candidateSets.length > 0

    scopeChain = (scope for scope in slick.parse(scopeChain)[0])
    while scopeChain.length > 0
      matchingSets = candidateSets
        .filter (set) -> set.matches(scopeChain)
        .sort (a, b) -> a.compare(b)

      if matchingSets.length > 0
        return matchingSets[0].getMultiple(keyPaths)

      scopeChain.pop()

    []

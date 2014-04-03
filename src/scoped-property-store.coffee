slick = require 'slick'
Selector = require './selector'
PropertySet = require './property-set'

# Public:
module.exports =
class ScopedPropertyStore
  constructor: ->
    @propertySets = []
    @escapeCharacterRegex = /[-!"#$%&'*+,/:;=?@|^~()<>{}[\]]/g

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
  getPropertyValue: (scopeChain, keyPath) ->
    candidateSets = @propertySets.filter (set) -> set.has(keyPath)
    return unless candidateSets.length > 0

    scopeChain = @parseScopeChain(scopeChain)
    while scopeChain.length > 0
      matchingSets = candidateSets
        .filter (set) -> set.matches(scopeChain)
        .sort (a, b) -> a.compare(b)
      if matchingSets.length > 0
        return matchingSets[0].get(keyPath)
      else
        scopeChain.pop()

    undefined

  # Public: Get *all* properties objects matching the given scope chain that
  # contain a value for given key path.
  #
  # scopeChain - This describes a location in the document. It uses the same
  #   syntax as selectors, with each space-separated component representing one
  #   element.
  # keyPath - An optional `.` separated string of keys that a properties object
  #   must contain in order to be included in the returned properties.
  #
  # Returns an {Array} of property {Object}s. These are the same objects that
  # are nested beneath the selectors in {::addProperties}.
  getProperties: (scopeChain, keyPath) ->
    values = []
    candidateSets = @propertySets
    candidateSets = @propertySets.filter((set) -> set.has(keyPath)) if keyPath?
    return values unless candidateSets.length > 0

    scopeChain = @parseScopeChain(scopeChain)
    while scopeChain.length > 0
      matchingSets = candidateSets
        .filter (set) -> set.matches(scopeChain)
        .sort (a, b) -> a.compare(b)
      values.push(matchingSets.map((set) -> set.properties)...)
      scopeChain.pop()

    values

  parseScopeChain: (scopeChain) ->
    scopeChain = scopeChain.replace @escapeCharacterRegex, (match) -> "\\#{match[0]}"
    scope for scope in slick.parse(scopeChain)[0]

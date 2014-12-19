{deepExtend, find} = require 'underscore-plus'
PropertySet = require './property-set'
Selector = require './selector'

# Public: A single layer of scoped properties in a cascade - analogous to a
# single stylesheet on a web page.
module.exports =
class Layer
  constructor: (@name, @priority, @counter, @owner) ->
    @propertySets = []

  # Public: Add or update properties in the {Layer}.
  #
  # * `propertiesBySelector` An {Object} whose keys are scope selector {String}s
  #   and whose values are {Object}s representing properties values to store.
  set: (propertiesBySelector) ->
    for selectorString, properties of propertiesBySelector
      for selector in Selector.create(selectorString)
        propertySet = find @propertySets, (set) ->
          set.selector.isEqual(selector)
        unless propertySet?
          propertySet = new PropertySet(selector, this)
          @propertySets.push(propertySet)
        deepExtend(propertySet.properties, properties)
    @owner.layerDidUpdate(this)

  # Public: Remove properties from the {Layer}.
  #
  # * `scopeSelector` A scope selector {String} from which to remove properties
  #   whose values were previously assigned using {::set}.
  # * `keyPath` (optional) A key-path {String} representing a subset of the
  #   properties to remove. If not provided, all properties for the selector
  #   will be removed.
  unset: (scopeSelector, keyPath) ->
    for selector in Selector.create(scopeSelector)
      propertySet = find @propertySets, (set) -> set.selector.isEqual(selector)
      if keyPath?
      else
        @propertySets.splice(@propertySets.indexOf(propertySet), 1)
    @owner.layerDidUpdate(this)

  # Public: Get an {Object} in the same format as the `propertiesBySelector`
  # argument to {::set}, representing all of the {Layer}'s properties.
  getPropertiesBySelector: ->
    result = {}
    for propertySet in @propertySets
      result[propertySet.selector.toString()] = propertySet.properties
    result

  # Public: Remove the {Layer} from the cascade.
  destroy: ->
    @owner.layerDidDestroy(this)

  # Public: Get an {Array} of all {PropertySet}s whose selectors match a scope.
  #
  # * `scopeChain` {String} See {ScopedPropertyStore::getPropertyValue}.
  getPropertySets: (scopeChain) ->
    result = []
    for _, propertySet of @propertySets
      if propertySet.selector.matches(scopeChain)
        result.push(propertySet)
    result

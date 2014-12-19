slick = require 'atom-slick'
_ = require 'underscore-plus'
{getValueAtKeyPath} = require 'key-path-helpers'
{deprecate} = require 'grim'
{Disposable, CompositeDisposable} = require 'event-kit'
Selector = require './selector'
{isPlainObject, checkValueAtKeyPath, deepDefaults} = require './helpers'
Layer = require './layer'

# Public: A set of key-value properties, associated with scope selectors.
# Property values are stored in a set of {Layer}s, analogous to a set of
# `Cascading Style Sheets`.
module.exports =
class ScopedPropertyStore
  constructor: ->
    @cache = {}
    @propertySets = []
    @layers = []
    @layerCounter = 0
    @escapeCharacterRegex = /[-!"#$%&'*+,/:;=?@|^~()<>{}[\]]/g

  # Public: Get a {Layer} by name
  #
  # * `name` {String} The name given when the {Layer} was added with {::addLayer}
  #
  # Returns a {Layer} or `undefined` if no such layer exists.
  getLayer: (name) ->
    _.find @layers, (layer) -> layer.name is name

  # Public: Get an {Array} of all the {Layer}s in the store.
  getLayers: ->
    @layers

  # Public: Add a new layer of properties to the cascade.
  #
  # * `name` A {String} name to associate with the layer. This name can
  #   later be used to retrieve or remove the layer.
  # * `options`
  #   * `priority` A {Number} that will be used to determine the layer's
  #     position in the cascade.
  #
  # Returns a {Layer}
  addLayer: (name, options) ->
    priority = options?.priority ? 0
    layer = @getLayer(name)
    if layer?
      layer.priority = priority
    else
      layer = new Layer(name, options?.priority ? 0, @layerCounter++, this)
      @layers.push(layer)
    @layers.sort (a, b) -> a.priority - b.priority
    layer

  # Deprecated: Add scoped properties to be queried with {::get}
  #
  # source - A string describing these properties to allow them to be removed
  #   later.
  # propertiesBySelector - An {Object} containing CSS-selectors mapping to
  #   {Objects} containing properties. For example: `{'.foo .bar': {x: 1, y: 2}`
  #
  # Returns a {Disposable} on which you can call `.dispose()` to remove the
  # added properties
  addProperties: (source, propertiesBySelector, options) ->
    deprecate("Use ::addLayer and Layer::set instead")
    layer = @addLayer(source, options)
    layer.set(propertiesBySelector)
    new Disposable ->
      deprecate("Use Layer::destroy instead of using this disposable")
      layer.destroy()

  # Public: Get the value of a previously stored key-path in a given scope.
  #
  # * `scopeChain` This describes a location in the document. It uses the same
  #   syntax as selectors, with each space-separated component representing one
  #   element.
  # * `keyPath` A `.` separated string of keys to traverse in the properties.
  # * `options`: (optional) {Object}
  #   * `includeLayers` (optional) an {Array} of {String} names of {Layer}s to
  #     use when calculating the value. By default, all {Layer}s are used.
  #   * `excludeLayers` (optional) an {Array} of {String} names of {Layer}s to
  #     *exclude* when calculating the value.
  #
  # Returns the property value or `undefined` if none is found.
  getPropertyValue: (originalScopeChain, keyPath, options) ->
    if not options? and @hasCachedValue(originalScopeChain, keyPath)
      return @getCachedValue(originalScopeChain, keyPath)
    value = @getMergedValue(originalScopeChain, keyPath, options)
    @setCachedValue(originalScopeChain, keyPath, value) unless options?
    value

  getMergedValue: (originalScopeChain, keyPath, options) ->
    {includeLayers, excludeLayers} = options if options?
    scopeChain = @parseScopeChain(originalScopeChain)

    mergedValue = undefined
    hasMergedValue = false

    while scopeChain.length > 0
      for set in @propertySets
        continue if excludeLayers? and (set.layer.name in excludeLayers)
        continue if includeLayers? and not (set.layer.name in includeLayers)

        if set.selector.matches(scopeChain)
          [value, hasValue] = checkValueAtKeyPath(set.properties, keyPath)
          if hasValue
            if hasMergedValue
              deepDefaults(mergedValue, value)
            else
              hasMergedValue = true
              mergedValue = value
            return mergedValue unless isPlainObject(mergedValue)

      scopeChain.pop()
    mergedValue

  # Deprecated: Get *all* property objects matching the given scope chain that
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
    deprecate("Call ::getPropertyValue with multiple scope chains instead")
    [@getPropertyValue(scopeChain, null)]

  # Public: Get *all* properties for a given source.
  #
  # ## Examples
  #
  # ```coffee
  # store.addProperties('some-source', {'.source.ruby': {foo: 'bar'}})
  # store.addProperties('some-source', {'.source.ruby': {omg: 'wow'}})
  # store.propertiesForSource('some-source') # => {'.source.ruby': {foo: 'bar', omg: 'wow'}}
  # ```
  #
  # * `source` {String}
  #
  # Returns an {Object} in the format {scope: {property: value}}
  propertiesForSource: (source) ->
    @getLayer(source).getPropertiesBySelector()

  # Public: Get *all* properties matching the given source and scopeSelector.
  #
  # * `source` {String}
  # * `scopeSelector` {String} `scopeSelector` is matched exactly.
  #
  # Returns an {Object} in the format {property: value}
  propertiesForSourceAndSelector: (source, scopeSelector) ->
    normalizedSelector = Selector.create(scopeSelector)[0].toString()
    @propertiesForSource(source)[normalizedSelector]

  # Public: Get *all* properties matching the given scopeSelector.
  #
  # * `scopeSelector` {String} `scopeSelector` is matched exactly.
  #
  # Returns an {Object} in the format {property: value}
  propertiesForSelector: (scopeSelector) ->
    normalizedSelector = Selector.create(scopeSelector)[0].toString()
    result = {}
    for propertySet in @propertySets
      if propertySet.selector.toString() is normalizedSelector
        deepDefaults(result, propertySet.properties)
    result

  # Deprecated: Remove all properties for a given source.
  #
  # * `source` {String}
  removePropertiesForSource: (name) ->
    deprecate("Use ::getLayer(name).destroy() instead")
    @getLayer(name).destroy()

  # Deprecated: Remove all properties for a given source.
  #
  # * `source` {String}
  # * `scopeSelector` {String} `scopeSelector` is matched exactly.
  removePropertiesForSourceAndSelector: (name, scopeSelector) ->
    deprecate("Use ::getLayer(name).unset(scopeSelector) instead")
    @getLayer(name).unset(scopeSelector)

  # Private - {Layer} owner hooks

  layerDidDestroy: (layer) ->
    index = @layers.indexOf(layer)
    @layers.splice(index, 1) if index >= 0
    @layerDidUpdate()

  layerDidUpdate: ->
    @propertySets = []
    for layer in @layers
      for propertySet in layer.propertySets
        @propertySets.push(propertySet)
    @propertySets.sort (a, b) ->
      (b.selector.specificity - a.selector.specificity) or
      (b.layer.priority - a.layer.priority) or
      (b.layer.counter - a.layer.counter)
    @bustCache()

  # Private - internal

  bustCache: ->
    @cache = {}

  hasCachedValue: (scope, keyPath) ->
    @cache.hasOwnProperty("#{scope}:#{keyPath}")

  getCachedValue: (scope, keyPath) ->
    @cache["#{scope}:#{keyPath}"]

  setCachedValue: (scope, keyPath, value) ->
    @cache["#{scope}:#{keyPath}"] = value

  parseScopeChain: (scopeChain) ->
    scopeChain = scopeChain.replace @escapeCharacterRegex, (match) -> "\\#{match[0]}"
    scope for scope in slick.parse(scopeChain)[0] ? []

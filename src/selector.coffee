slick = require 'slick'

module.exports =
class Selector
  @create: (source) ->
    new this(ast) for ast in slick.parse(source)

  constructor: (@selector) ->

  matches: (scopeChain) ->
    scopeChain = slick.parse(scopeChain)[0]

    selectorIndex = @selector.length - 1
    scopeIndex = scopeChain.length - 1

    requireMatch = true
    while selectorIndex >= 0 and scopeIndex >= 0
      if @selectorComponentMatchesScope(@selector[selectorIndex], scopeChain[scopeIndex])
        requireMatch = @selector[selectorIndex].combinator is '>'
        selectorIndex--
      else if requireMatch
        return false

      scopeIndex--

    selectorIndex < 0

  selectorComponentMatchesScope: (selectorComponent, scope) ->
    if selectorComponent.classList?
      for className in selectorComponent.classList
        return false unless scope.classes[className]?

    if selectorComponent.tag?
      return false unless selectorComponent.tag is scope.tag

    if selectorComponent.attributes?
      scopeAttributes = {}
      for attribute in scope.attributes ? []
        scopeAttributes[attribute.name] = attribute
      for attribute in selectorComponent.attributes
        return false unless scopeAttributes[attribute.name]?.value is attribute.value

    true

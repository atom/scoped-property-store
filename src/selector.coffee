slick = require 'slick'

module.exports =
class Selector
  constructor: (@source) ->

  getAst: ->
    @ast ?= slick.parse(@source)

  matches: (scopeChain) ->
    scopeChainAst = slick.parse(scopeChain)[0]
    for selectorAst in @getAst()
      if @selectorMatchesScopeChain(selectorAst, scopeChainAst)
        return true
    false

  selectorMatchesScopeChain: (selector, scopeChain) ->
    selectorIndex = selector.length - 1
    scopeIndex = scopeChain.length - 1

    @selectorComponentMatchesScope(selector[selectorIndex], scopeChain[scopeIndex])

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

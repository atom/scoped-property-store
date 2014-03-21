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
    for className in selectorComponent.classList
      return false unless scope.classes[className]?
    true

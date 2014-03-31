slick = require 'slick'

indexCounter = 0

module.exports =
class Selector
  @create: (source) ->
    for selectorAst in slick.parse(source)
      @parsePseudoSelectors(selectorComponent) for selectorComponent in selectorAst
      new this(selectorAst)

  @parsePseudoSelectors: (selectorComponent) ->
    return unless selectorComponent.pseudos?
    for pseudoClass in selectorComponent.pseudos
      if pseudoClass.name is 'not'
        selectorComponent.notSelectors ?= []
        selectorComponent.notSelectors.push(@create(pseudoClass.value)...)
      else
        console.warn "Unsupported pseudo-selector: #{pseudoClass.name}"

  constructor: (@selector) ->
    @specificity = @calculateSpecificity()
    @index = indexCounter++

  matches: (scopeChain) ->
    if typeof scopeChain is 'string'
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
        return false unless scope.classes?[className]?

    if selectorComponent.tag?
      return false unless selectorComponent.tag is scope.tag or selectorComponent.tag is '*'

    if selectorComponent.attributes?
      scopeAttributes = {}
      for attribute in scope.attributes ? []
        scopeAttributes[attribute.name] = attribute
      for attribute in selectorComponent.attributes
        return false unless scopeAttributes[attribute.name]?.value is attribute.value

    if selectorComponent.notSelectors?
      for selector in selectorComponent.notSelectors
        return false if selector.matches([scope])

    true

  compare: (other) ->
    if other.specificity is @specificity
      other.index - @index
    else
      other.specificity - @specificity

  calculateSpecificity: ->
    a = 0
    b = 0
    c = 0

    for selectorComponent in @selector
      if selectorComponent.classList?
        b += selectorComponent.classList.length

      if selectorComponent.attributes?
        b += selectorComponent.attributes.length

      if selectorComponent.tag?
        c += 1

    (a * 100) + (b * 10) + (c * 1)

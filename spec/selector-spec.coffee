Selector = require '../src/selector'

describe "Selector", ->
  S = (string) -> new Selector(string)

  describe "::matches(scopeChain)", ->
    describe "for selectors with no combinators", ->
      it "can match based on class name", ->
        expect(S('.foo').matches('.bar .foo')).toBe true
        expect(S('.foo').matches('.foo .bar')).toBe false
        expect(S('.foo').matches('.bar .foo.bar')).toBe true

      it "can match based on element type", ->
        expect(S('p').matches('div p')).toBe true
        expect(S('p').matches('div div')).toBe false
        expect(S('p').matches('div p.foo')).toBe true

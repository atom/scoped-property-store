Selector = require '../src/selector'

describe "Selector", ->
  S = (string) -> new Selector(string)

  describe "::matches(scopeChain)", ->
    describe "for selectors with no combinators", ->
      it "can match scope chains based on class name", ->
        expect(S('.foo').matches('.bar .foo')).toBe true
        expect(S('.foo').matches('.foo .bar')).toBe false
        expect(S('.foo').matches('.bar .foo.bar')).toBe true

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

      it "can match based on attributes", ->
        expect(S('[foo=bar][baz=qux]').matches('div [foo=bar][baz=qux]')).toBe true
        expect(S('[foo=bar][baz=qux]').matches('div [foo=bar]')).toBe false

    describe "for selectors with descendant combinators", ->
      it "matches based on the ancestry of the chain's rightmost element", ->
        expect(S('.foo .bar').matches('.baz .foo .bar')).toBe true
        expect(S('.foo .bar').matches('.baz .bar')).toBe false
        expect(S('.foo .bar').matches('.foo .baz .bar')).toBe true

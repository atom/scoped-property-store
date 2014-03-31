Selector = require '../src/selector'

describe "Selector", ->
  S = (string) -> Selector.create(string)[0]

  describe "::matches(scopeChain)", ->
    describe "for selectors with no combinators", ->
      it "can match based on the class name of the rightmost element", ->
        expect(S('.foo').matches('.bar .foo')).toBe true
        expect(S('.foo').matches('.foo .bar')).toBe false
        expect(S('.foo').matches('.bar .foo.bar')).toBe true

      it "can match based on the type of the rightmost element", ->
        expect(S('p').matches('div p')).toBe true
        expect(S('p').matches('div div')).toBe false
        expect(S('p').matches('div p.foo')).toBe true

      it "can match based on the attributes of the rightmost element", ->
        expect(S('[foo=bar][baz=qux]').matches('div [foo=bar][baz=qux]')).toBe true
        expect(S('[foo=bar][baz=qux]').matches('div [foo=bar]')).toBe false

      it "allows selectors not specifying a specific tag to match scopes with specific tags", ->
        expect(S('.foo').matches('div.foo')).toBe true

      it "allows classes such as .c\\+\\+", ->
        expect(S('.c\\+\\+').matches('.c\\+\\+')).toBe true

    describe "for selectors with descendant combinators", ->
      it "matches based on the ancestors of the chain's rightmost element", ->
        expect(S('.foo .bar').matches('.baz .foo .bar')).toBe true
        expect(S('.foo .bar').matches('.baz .bar')).toBe false
        expect(S('.foo .bar').matches('.foo .baz .bar')).toBe true

    describe "for selectors with child combinators", ->
      it "matches based on the parent of the chain's rightmost element", ->
        expect(S('.foo > .bar').matches('.baz .foo .bar')).toBe true
        expect(S('.foo > .bar').matches('.baz .bar')).toBe false
        expect(S('.foo > .bar').matches('.foo .baz .bar')).toBe false

    describe "for selectors with :not pseudoclasses", ->
      it "does not match if the portion of the selector within the negation matches", ->
        expect(S('.foo:not(.bar, .baz)').matches('.baz .foo.bar')).toBe false
        expect(S('.foo:not(.bar, .baz)').matches('.baz .foo.baz')).toBe false
        expect(S('.foo:not(.bar, .baz)').matches('.baz .foo.qux')).toBe true

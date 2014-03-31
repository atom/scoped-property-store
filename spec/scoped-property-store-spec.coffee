ScopedPropertyStore = require '../src/scoped-property-store'

describe "ScopedPropertyStore", ->
  store = null

  beforeEach ->
    store = new ScopedPropertyStore

  describe "::getPropertyValue(scopeChain, keyPath)", ->
    it "returns the property with the most specific scope selector for the given scope chain", ->
      store.addProperties 'test',
        '.a .c.d.e': {x: y: 1}
        '.a .c': {x: y: 2}
        '.a': {x: y: 3}

      expect(store.getPropertyValue('.a .c.d.e.f', 'x.y')).toBe 1
      expect(store.getPropertyValue('.a .c', 'x.y')).toBe 2
      expect(store.getPropertyValue('.a .g', 'x.y')).toBe 3
      expect(store.getPropertyValue('.a', 'x.y')).toBe 3
      expect(store.getPropertyValue('.y', 'x.y')).toBeUndefined()

    it "favors the most recently added properties in the event of a specificity tie", ->
      store.addProperties('test', '.a.b .c': 'x': 1)
      store.addProperties('test', '.a .c.d': 'x': 2)

      expect(store.getPropertyValue('.a.b .c.d', 'x')).toBe 2
      expect(store.getPropertyValue('.a.b .c', 'x')).toBe 1

    it "escapes non-whitespace combinators in the scope chain", ->
      store.addProperties 'test',
        '.c\\+\\+': a: 1
        '.c\\>': a: 2
        '.c\\~': a: 3

      expect(store.getPropertyValue('.c++', 'a')).toBe 1
      expect(store.getPropertyValue('.c>', 'a')).toBe 2
      expect(store.getPropertyValue('.c~', 'a')).toBe 3

  describe "::getProperties(scopeChain, keyPath)", ->
    beforeEach ->
      store.addProperties 'test',
        '.a .b .c.d': x: 1, y: 2
        '.a .b .c': x: 2
        '.a .b': x: undefined
        '.a': x: 3

      store.addProperties 'test',
        '.a .b .c': q: 4

    describe "when a keyPath is provided", ->
      it "gets all properties matching the given scope that contain the given key path, ordered by specificity", ->
        expect(store.getProperties('.a .b .c.d', 'x')).toEqual [{x: 1, y: 2}, {x: 2}, {x: undefined}, {x: 3}]

    describe "when no keyPath is provided", ->
      it "gets all properties matching the given scope", ->
        expect(store.getProperties('.a .b .c.d')).toEqual [{x: 1, y: 2}, {q: 4}, {x: 2}, {x: undefined}, {x: 3}]

  describe "::removeProperties(source)", ->
    it "removes properties previously added with ::addProperties", ->
      store.addProperties('test1', '.a.b': 'x': 1)
      store.addProperties('test2', '.a': 'x': 2)

      expect(store.getPropertyValue('.a.b', 'x')).toBe 1
      store.removeProperties('test1')
      expect(store.getPropertyValue('.a.b', 'x')).toBe 2

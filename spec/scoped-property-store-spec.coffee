ScopedPropertyStore = require '../src/scoped-property-store'

describe "ScopedPropertyStore", ->
  store = null

  beforeEach ->
    store = new ScopedPropertyStore

  describe "::get(scopeChain, keyPath)", ->
    it "returns the property with the most specific scope selector for the given scope chain", ->
      store.addProperties 'test',
        '.a .c.d.e': {x: y: 1}
        '.a .c': {x: y: 2}
        '.a': {x: y: 3}

      expect(store.get('.a .c.d.e.f', 'x.y')).toBe 1
      expect(store.get('.a .c', 'x.y')).toBe 2
      expect(store.get('.a .g', 'x.y')).toBe 3
      expect(store.get('.a', 'x.y')).toBe 3
      expect(store.get('.y', 'x.y')).toBeUndefined()

    it "favors the most recently added properties in the event of a specificity tie", ->
      store.addProperties('test', '.a.b .c': 'x': 1)
      store.addProperties('test', '.a .c.d': 'x': 2)

      expect(store.get('.a.b .c.d', 'x')).toBe 2
      expect(store.get('.a.b .c', 'x')).toBe 1

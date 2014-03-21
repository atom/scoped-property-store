ScopedPropertyStore = require '../src/scoped-property-store'

describe "ScopedPropertyStore", ->
  store = null

  beforeEach ->
    store = new ScopedPropertyStore

  describe "::get(scopeChain, keyPath)", ->
    it "returns the property with the most specific scope selector for the given scope chain", ->
      store.addProperties 'test',
        '.a .c.d.e': x: 1
        '.a .c': x: 2
        '.a': x: 3

      expect(store.get('.a .c.d.e.f', 'x')).toBe 1
      expect(store.get('.a .c', 'x')).toBe 2
      expect(store.get('.a .g', 'x')).toBe 3
      expect(store.get('.a', 'x')).toBe 3
      expect(store.get('.y', 'x')).toBeUndefined()

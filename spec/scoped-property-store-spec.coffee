ScopedPropertyStore = require '../src/scoped-property-store'

describe "ScopedPropertyStore", ->
  store = null

  beforeEach ->
    store = new ScopedPropertyStore

  describe "::addLayer(name, {priority})", ->
    it "adds the layer to the cascade, positioned according to its priority", ->
      expect(store.getLayers()).toEqual([])

      layer1 = store.addLayer('first-source', priority: Infinity)
      layer2 = store.addLayer('second-source', priority: 1)
      layer3 = store.addLayer('third-source', priority: 2)

      expect(store.getLayers()).toEqual([layer2, layer3, layer1])

    it "assumes a default priority of zero", ->
      layer1 = store.addLayer('first-source', priority: 1)
      layer2 = store.addLayer('third-source', priority: -1)
      layer3 = store.addLayer('second-source')

      expect(store.getLayers()).toEqual([layer2, layer3, layer1])

    it "allows the layer to later be retrieved by name", ->
      expect(store.getLayer('first-layer')).toBeUndefined()
      layer = store.addLayer('first-layer')
      expect(store.getLayer('first-layer')).toBe(layer)

    it "allows the layer to later be destroyed", ->
      layer = store.addLayer('first-layer')
      layer.destroy()
      expect(store.getLayers()).toEqual([])

    describe "when a layer with the given name already exists", ->
      it "reassigns the layer's priority and returns it", ->
        layer1 = store.addLayer('x', priority: 2)
        layer2 = store.addLayer('y')
        expect(store.getLayers()).toEqual([layer2, layer1])

        expect(store.addLayer('x', priority: -1)).toBe(layer1)
        expect(store.getLayers()).toEqual([layer1, layer2])

  describe "::getPropertyValue(scopeChain, keyPath)", ->
    it "returns the property with the most specific scope selector for the given scope chain", ->
      store.addLayer('test').set
        '.c': {x: y: 3}
        '.b .c': {x: y: 2}
        '.a .b .c': {x: y: 1}
        '.a .b .c.d': {x: y: 0}

      expect(store.getPropertyValue('.a .b .c.d', 'x.y')).toBe 0
      expect(store.getPropertyValue('.a .b .c', 'x.y')).toBe 1
      expect(store.getPropertyValue('.other .b .c', 'x.y')).toBe 2
      expect(store.getPropertyValue('.other .stuff .c', 'x.y')).toBe 3

    it "returns properties that match parent scopes if none match the exact scope", ->
      store.addLayer('test').set
        '.a .b.c': {x: y: 3}
        '.d.e': {x: y: 2}
        '.f': {x: y: 1}

      expect(store.getPropertyValue('.a .b.c .d.e .f', 'x.y')).toBe 1
      expect(store.getPropertyValue('.a .b.c .d.e .g', 'x.y')).toBe 2
      expect(store.getPropertyValue('.a .b.c .d.x .g', 'x.y')).toBe 3
      expect(store.getPropertyValue('.y', 'x.y')).toBeUndefined()

    it "deep-merges all values for the given key path", ->
      store.addLayer('test').set
        '.a': {t: u: v: 1}
        '.a .b': {t: u: w: 2}
        '.a .b .c': {t: x: 3}

      expect(store.getPropertyValue('.a .b .c', 't.u')).toEqual {v: 1, w: 2}
      expect(store.getPropertyValue('.a .b .c', 't')).toEqual {u: {v: 1, w: 2}, x: 3}
      expect(store.getPropertyValue('.a .b .c', null)).toEqual {t: {u: {v: 1, w: 2}, x: 3}}

      store.getLayer('test').set('.a .b .c': {t: u: false})
      expect(store.getPropertyValue('.a .b .c', 't.u')).toBe false
      expect(store.getPropertyValue('.a .b .c', 't')).toEqual {u: false, x: 3}
      expect(store.getPropertyValue('.a .b .c', null)).toEqual {t: {u: false, x: 3}}

      store.getLayer('test').set('.a .b .c': {t: null})
      expect(store.getPropertyValue('.a .b .c', 't.u')).toEqual undefined
      expect(store.getPropertyValue('.a .b .c', 't')).toEqual null
      expect(store.getPropertyValue('.a .b .c', null)).toEqual {t: null}

    it "favors the most recently added layers in the event of a specificity and priority tie", ->
      store.addLayer('test1', priority: 1).set('.a.b .c': 'x': 1)
      store.addLayer('test2', priority: 1).set('.a .c.d': 'x': 2)

      expect(store.getPropertyValue('.a.b .c.d', 'x')).toBe 2
      expect(store.getPropertyValue('.a.b .c', 'x')).toBe 1

    it "escapes non-whitespace combinators in the scope chain", ->
      store.addLayer('test').set
        '.c\\+\\+': a: 1
        '.c\\>': a: 2
        '.c\\~': a: 3
        '.c\\-': a: 4
        '.c\\!': a: 5
        '.c\\"': a: 6
        '.c\\#': a: 7
        '.c\\$': a: 8
        '.c\\%': a: 9
        '.c\\&': a: 10
        '.c\\\'': a: 11
        '.c\\*': a: 12
        '.c\\,': a: 13
        '.c\\/': a: 14
        '.c\\:': a: 15
        '.c\\;': a: 16
        '.c\\=': a: 17
        '.c\\?': a: 18
        '.c\\@': a: 19
        '.c\\|': a: 20
        '.c\\^': a: 21
        '.c\\(': a: 22
        '.c\\)': a: 23
        '.c\\<': a: 24
        '.c\\{': a: 25
        '.c\\}': a: 26
        '.c\\[': a: 27
        '.c\\]': a: 28

      expect(store.getPropertyValue('.c++', 'a')).toBe 1
      expect(store.getPropertyValue('.c>', 'a')).toBe 2
      expect(store.getPropertyValue('.c~', 'a')).toBe 3
      expect(store.getPropertyValue('.c-', 'a')).toBe 4
      expect(store.getPropertyValue('.c!', 'a')).toBe 5
      expect(store.getPropertyValue('.c"', 'a')).toBe 6
      expect(store.getPropertyValue('.c#', 'a')).toBe 7
      expect(store.getPropertyValue('.c$', 'a')).toBe 8
      expect(store.getPropertyValue('.c%', 'a')).toBe 9
      expect(store.getPropertyValue('.c&', 'a')).toBe 10
      expect(store.getPropertyValue('.c\'', 'a')).toBe 11
      expect(store.getPropertyValue('.c*', 'a')).toBe 12
      expect(store.getPropertyValue('.c,', 'a')).toBe 13
      expect(store.getPropertyValue('.c/', 'a')).toBe 14
      expect(store.getPropertyValue('.c:', 'a')).toBe 15
      expect(store.getPropertyValue('.c;', 'a')).toBe 16
      expect(store.getPropertyValue('.c=', 'a')).toBe 17
      expect(store.getPropertyValue('.c?', 'a')).toBe 18
      expect(store.getPropertyValue('.c@', 'a')).toBe 19
      expect(store.getPropertyValue('.c|', 'a')).toBe 20
      expect(store.getPropertyValue('.c^', 'a')).toBe 21
      expect(store.getPropertyValue('.c(', 'a')).toBe 22
      expect(store.getPropertyValue('.c)', 'a')).toBe 23
      expect(store.getPropertyValue('.c<', 'a')).toBe 24
      expect(store.getPropertyValue('.c{', 'a')).toBe 25
      expect(store.getPropertyValue('.c}', 'a')).toBe 26
      expect(store.getPropertyValue('.c[', 'a')).toBe 27
      expect(store.getPropertyValue('.c]', 'a')).toBe 28
      expect(store.getPropertyValue('()', 'a')).toBeUndefined()

    it "favors higher-priority layers in the event of a specificity tie", ->
      store.addLayer('test2').set('.a.b': {x: y: 2})
      store.addLayer('test1', priority: 100).set('.a.b': {x: y: 1})
      store.addLayer('test3').set('.a.b': {x: y: 3})

      expect(store.getPropertyValue('.a.b', 'x.y')).toBe 1

    describe "when the 'includeLayers' option is provided", ->
      it "returns property values from the specified layers", ->
        store.addLayer('test1').set('.a.b': {x: y: 1})
        store.addLayer('test2').set('.a.b': {x: y: 2})
        store.addLayer('test3', priority: 100).set('.a.b': {x: y: 3})

        expect(store.getPropertyValue('.a.b', 'x.y', includeLayers: ['test1'])).toBe 1
        expect(store.getPropertyValue('.a.b', 'x.y')).toBe 3 # shouldn't cache the previous call

    describe "when the 'excludeLayers' options is used", ->
      it "returns properties set on sources excluding the layers specified", ->
        store.addLayer('test1').set('.a.b': {x: y: 1})
        store.addLayer('test2', priority: 50).set('.a.b': {x: y: 2})
        store.addLayer('test3', priority: 100).set('.a.b': {x: y: 3})

        expect(store.getPropertyValue('.a.b', 'x.y', excludeLayers: ['test3'])).toBe 2
        expect(store.getPropertyValue('.a.b', 'x.y', excludeLayers: ['test2', 'test3'])).toBe 1
        expect(store.getPropertyValue('.a.b', 'x.y')).toBe 3 # shouldn't cache the previous call

  describe "deprecated ::getProperties(scopeChain, keyPath)", ->
    beforeEach ->
      store.addProperties 'test',
        '.a .b .c.d': x: 1, y: 2
        '.a .b .c': x: 2
        '.a .b': x: undefined
        '.a': x: 3

      store.addProperties 'test',
        '.a .b .c': q: 4

    describe "when no keyPath is provided", ->
      it "gets all properties matching the given scope", ->
        expect(store.getProperties('.a .b .c.d')).toEqual [{x: 1, y: 2, q: 4}]

  describe "removing properties", ->
    describe "when ::removePropertiesForSource(source) is used", ->
      it "removes properties previously added with ::addProperties", ->
        store.addProperties('test1', '.a.b': 'x': 1)
        store.addProperties('test2', '.a': 'x': 2)

        expect(store.getPropertyValue('.a.b', 'x')).toBe 1
        store.removePropertiesForSource('test1')
        expect(store.getPropertyValue('.a.b', 'x')).toBe 2

    describe "when ::removePropertiesForSourceAndSelector(source, selector) is used", ->
      it "removes properties previously added with ::addProperties", ->
        store.addProperties('default', '.a.b': 'x': 1)
        store.addProperties('default', '.a.b': 'x': 2)
        store.addProperties('override', '.a': 'x': 3)
        store.addProperties('override', '.a.b': 'x': 4)

        expect(store.getPropertyValue('.a', 'x')).toBe 3
        expect(store.getPropertyValue('.a.b', 'x')).toBe 4
        store.removePropertiesForSourceAndSelector('override', '.b.a')
        expect(store.getPropertyValue('.a', 'x')).toBe 3
        expect(store.getPropertyValue('.a.b', 'x')).toBe 2

    describe "when Disposable::dispose() is used", ->
      it "removes properties previously added with ::addProperties", ->
        disposable1 = store.addProperties('test1', '.a.b': 'x': 1)
        disposable2 = store.addProperties('test2', '.a': 'x': 2)

        expect(store.getPropertyValue('.a.b', 'x')).toBe 1
        disposable1.dispose()
        expect(store.getPropertyValue('.a.b', 'x')).toBe 2
        disposable2.dispose()
        expect(store.getPropertyValue('.a.b', 'x')).toBeUndefined()

  describe "::propertiesForSource(source)", ->
    it 'returns all the properties for a given source', ->
      store.addProperties('a', '.a.b': 'x': 1)
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.a.b': 'y': 1)

      properties = store.propertiesForSource('b')
      expect(properties).toEqual
        '.a':
          x: 2
        '.a.b':
          y: 1

    it 'can compose properties when they have nested properties', ->
      store.addProperties 'b', '.a.b': {foo: {bar: 'ruby'}}
      store.addProperties 'b', '.a.b': {foo: {omg: 'wow'}}

      expect(store.propertiesForSource('b')).toEqual
        '.a.b':
          foo:
            bar: 'ruby'
            omg: 'wow'

    it 'can compose properties added at different times for matching keys', ->
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.a.b': 'y': 1)
      store.addProperties('b', '.a.b': 'z': 3, 'y': 5)
      store.addProperties('b', '.o.k': 'y': 10)

      expect(store.propertiesForSource('b')).toEqual
        '.a':
          x: 2
        '.a.b':
          y: 5
          z: 3
        '.k.o':
          y: 10

    it 'will break out composite selectors', ->
      store.addProperties('b', '.a, .a.b, .a.b.c': 'x': 2)

      expect(store.propertiesForSource('b')).toEqual
        '.a':
          x: 2
        '.a.b':
          x: 2
        '.a.b.c':
          x: 2

  describe "::propertiesForSourceAndSelector(source, selector)", ->
    it 'returns all the properties for a given source', ->
      store.addProperties('a', '.a.b': 'x': 1)
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.a.b': 'y': 1)

      properties = store.propertiesForSourceAndSelector('b', '.b.a')
      expect(properties).toEqual y: 1

    it 'can compose properties added at different times for matching keys', ->
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.o.k': 'y': 1)
      store.addProperties('b', '.o.k': 'z': 3, 'y': 5)
      store.addProperties('b', '.a.b': 'y': 10)

      expect(store.propertiesForSourceAndSelector('b', '.o.k')).toEqual y: 5, z: 3

  describe "::propertiesForSelector(selector)", ->
    it 'returns all the properties for a given source', ->
      store.addProperties('a', '.a.b': 'x': 1)
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.a.b': 'y': 1)

      properties = store.propertiesForSelector('.b.a')
      expect(properties).toEqual x: 1, y: 1

    it 'can compose properties added at different times for matching keys', ->
      store.addProperties('b', '.a': 'x': 2)
      store.addProperties('b', '.o.k': 'y': 1)
      store.addProperties('a', '.o.k': 'z': 3, 'y': 5)
      store.addProperties('b', '.a.b': 'y': 10)

      expect(store.propertiesForSelector('.o.k')).toEqual y: 5, z: 3

{checkValueAtKeyPath, deepDefaults} = require '../src/helpers'

describe "Helpers", ->
  describe ".checkValueAtKeyPath", ->
    describe "when the object is a primitive", ->
      it "indicates that the object affects the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath(null, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

        [value, hasValue] = checkValueAtKeyPath(5, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

    describe "when one of the object's children on the key-path is a primitive", ->
      it "indicates that the object affects the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath({the: 5}, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

        [value, hasValue] = checkValueAtKeyPath({the: key: 5}, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

    describe "when the object is of a custom type", ->
      class Thing

      it "indicates that the object affects the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath(new Thing, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

    describe "when one of the object's children on the key-path is of a custom type", ->
      class Thing

      it "indicates that the object affects the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath({the: new Thing}, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

        [value, hasValue] = checkValueAtKeyPath({the: {key: new Thing}}, 'the.key.path')
        expect(value).toBeUndefined()
        expect(hasValue).toBe true

    describe "when the object has a value for the given key-path", ->
      it "indicates that the object affects the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath({the: key: path: 5}, 'the.key.path')
        expect(value).toBe 5
        expect(hasValue).toBe true

    describe "when the object doesn't have a value for the given key-path", ->
      it "indicates that the object doesn't affect the given key-path", ->
        [value, hasValue] = checkValueAtKeyPath({the: other: path: 5}, 'the.key.path')
        expect(value).toBe undefined
        expect(hasValue).toBe false

  describe ".deepDefaults", ->
    it "fills in missing values on the target object", ->
      target =
        one: 1
        two: 2
        nested:
          a: 'a'
          b: 'b'

      defaults =
        one: 100
        three: 300
        nested:
          a: 'A'
          c: 'C'

      deepDefaults(target, defaults)

      expect(target).toEqual
        one: 1
        two: 2
        three: 300
        nested:
          a: 'a'
          b: 'b'
          c: 'C'

    it "does nothing if the target isn't a plain object", ->
      class Thing

      target = new Thing

      defaults = {one: 1}

      deepDefaults(target, defaults)
      expect(target.hasOwnProperty('one')).toBe false

      target = "stuff"
      deepDefaults(target, defaults)
      expect(target.hasOwnProperty('one')).toBe false

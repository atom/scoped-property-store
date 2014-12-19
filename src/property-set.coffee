# Public: A set of properties associated with a {Selector}
module.exports =
class PropertySet
  constructor: (@selector, @layer) ->
    @properties = {}

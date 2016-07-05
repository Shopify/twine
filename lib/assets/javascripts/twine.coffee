((root, factory) ->
  if typeof root.define == 'function' && root.define.amd
    root.define([], factory)
  else if typeof module == 'object' && module.exports
    module.exports = factory()
  else
    root.Twine = factory()
)(this, ->
  Twine = {}
  Twine.shouldDiscardEvent = {}

  # Map of node binding ids to objects that describe a node's bindings.
  elements = {}

  # Registered components to look up
  registry = {}

  # The number of nodes bound since the last call to Twine.reset().
  # Used to determine the next binding id.
  nodeCount = 0

  # Storage for all bindable data, provided by the caller of Twine.reset().
  rootContext = null

  keypathRegex = /^[a-z]\w*(\.[a-z]\w*|\[\d+\])*$/i # Tests if a string is a pure keypath.
  refreshQueued = false
  rootNode = null

  currentBindingCallbacks = null

  Twine.getAttribute = (node, attr) ->
    node.getAttribute("data-#{attr}") || node.getAttribute(attr)

  # Cleans up all existing bindings and sets the root node and context.
  Twine.reset = (newContext, node = document.documentElement) ->
    for key of elements
      if bindings = elements[key]?.bindings
        obj.teardown() for obj in bindings when obj.teardown

    elements = {}

    rootContext = newContext
    rootNode = node
    rootNode.bindingId = nodeCount = 1

    this

  Twine.bind = (node = rootNode, context = Twine.context(node)) ->
    bind(context, node, getIndexesForElement(node), true)

  Twine.afterBound = (callback) ->
    if currentBindingCallbacks
      currentBindingCallbacks.push(callback)
    else
      callback()

  bind = (context, node, indexes, forceSaveContext) ->
    currentBindingCallbacks = []
    if node.bindingId
      Twine.unbind(node)

    if defineArrayAttr = Twine.getAttribute(node, 'define-array')
      newIndexes = defineArray(node, context, defineArrayAttr)
      indexes ?= {}
      for key, value of indexes when !newIndexes.hasOwnProperty(key)
        newIndexes[key] = value
      indexes = newIndexes
      # register the element early because subsequent bindings on the same node might need to make use of the index
      element = findOrCreateElementForNode(node)
      element.indexes = indexes

    for type, binding of Twine.bindingTypes when definition = Twine.getAttribute(node, type)
      element = findOrCreateElementForNode(node)
      element.bindings ?= []
      element.indexes ?= indexes

      fn = binding(node, context, definition, element)
      element.bindings.push(fn) if fn

    if newContextKey = Twine.getAttribute(node, 'context')
      keypath = keypathForKey(node, newContextKey)
      if keypath[0] == '$root'
        context = rootContext
        keypath = keypath.slice(1)
      context = getValue(context, keypath) || setValue(context, keypath, {})

    if element || newContextKey || forceSaveContext
      element = findOrCreateElementForNode(node)
      element.childContext = context
      element.indexes ?= indexes if indexes?

    callbacks = currentBindingCallbacks

    # IE and Safari don't support node.children for DocumentFragment and SVGElement nodes.
    # If the element supports children we continue to traverse the children, otherwise
    # we stop traversing that subtree.
    # https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.children
    # As a result, Twine are unsupported within DocumentFragment and SVGElement nodes.
    bind(context, childNode, if newContextKey? then null else indexes) for childNode in (node.children || [])
    Twine.count = nodeCount

    for callback in callbacks || []
      callback()
    currentBindingCallbacks = null

    Twine

  findOrCreateElementForNode = (node) ->
    node.bindingId ?= ++nodeCount
    elements[node.bindingId] ?= {}

  # Queues a refresh of the DOM, batching up calls for the current synchronous block.
  Twine.refresh = ->
    return if refreshQueued
    refreshQueued = true
    setTimeout(Twine.refreshImmediately, 0)

  refreshElement = (element) ->
    (obj.refresh() if obj.refresh?) for obj in element.bindings if element.bindings
    return

  Twine.refreshImmediately = ->
    refreshQueued = false
    refreshElement(element) for key, element of elements
    return

  Twine.register = (name, component) ->
    if registry[name]
      throw new Error("Twine error: '#{name}' is already registered with Twine")
    else
      registry[name] = component

  # Force the binding system to recognize programmatic changes to a node's value.
  Twine.change = (node, bubble = false) ->
    event = document.createEvent("HTMLEvents")
    event.initEvent('change', bubble, true) # for IE 9/10 compatibility.
    node.dispatchEvent(event)

  # Cleans up everything related to a node and its subtree.
  Twine.unbind = (node) ->
    if id = node.bindingId
      if bindings = elements[id]?.bindings
        obj.teardown() for obj in bindings when obj.teardown
      delete elements[id]
      delete node.bindingId


    # IE and Safari don't support node.children for DocumentFragment or SVGElement,
    # See explaination in bind()
    Twine.unbind(childNode) for childNode in (node.children || [])
    this

  # Returns the binding context for a node by looking up the tree.
  Twine.context = (node) -> getContext(node, false)
  Twine.childContext = (node) -> getContext(node, true)

  getContext = (node, child) ->
    while node
      return rootContext if node == rootNode
      node = node.parentNode if !child
      if !node
        console.warn "Unable to find context; please check that the node is attached to the DOM that Twine has bound, or that bindings have been initiated on this node's DOM"
        return null
      if (id = node.bindingId) && (context = elements[id]?.childContext)
        return context
      node = node.parentNode if child

  getIndexesForElement = (node) ->
    firstContext = null
    while node
      return elements[id]?.indexes if id = node.bindingId
      node = node.parentNode

  # Returns the fully qualified key for a node's context
  Twine.contextKey = (node, lastContext) ->
    keys = []
    addKey = (context) ->
      for key, val of context when lastContext == val
        keys.unshift(key)
        break
      lastContext = context

    while node && node != rootNode && node = node.parentNode
      addKey(context) if (id = node.bindingId) && (context = elements[id]?.childContext)

    addKey(rootContext) if node == rootNode
    keys.join('.')

  valuePropertyForNode = (node) ->
    name = node.nodeName.toLowerCase()
    if name in ['input', 'textarea', 'select']
      if node.getAttribute('type') in ['checkbox', 'radio'] then 'checked' else 'value'
    else
      'textContent'

  keypathForKey = (node, key) ->
    keypath = []
    for key, i in key.split('.')
      if (start = key.indexOf('[')) != -1
        if i == 0
          keypath.push(keyWithArrayIndex(key.substr(0, start), node)...)
        else
          keypath.push(key.substr(0, start))
        key = key.substr(start)

        while (end = key.indexOf(']')) != -1
          keypath.push(parseInt(key.substr(1, end), 10))
          key = key.substr(end + 1)
      else
        if i == 0
          keypath.push(keyWithArrayIndex(key, node)...)
        else
          keypath.push(key)
    keypath

  keyWithArrayIndex = (key, node) ->
    index = elements[node.bindingId]?.indexes?[key]
    if index?
      [key, index]
    else
      [key]

  getValue = (object, keypath) ->
    object = object[key] for key in keypath when object?
    object

  setValue = (object, keypath, value) ->
    [keypath..., lastKey] = keypath
    for key in keypath
      object = object[key] ?= {}
    object[lastKey] = value

  stringifyNodeAttributes = (node) ->
    [].map.call(node.attributes, (attr) -> "#{attr.name}=#{JSON.stringify(attr.value)}").join(' ')

  wrapFunctionString = (code, args, node) ->
    if isKeypath(code) && keypath = keypathForKey(node, code)
      if keypath[0] == '$root'
        ($context, $root) -> getValue($root, keypath)
      else
        ($context, $root) -> getValue($context, keypath)
    else
      code = "return #{code}"
      code = "with($arrayPointers) { #{code} }" if nodeArrayIndexes(node)
      code = "with($registry) { #{code} }" if requiresRegistry(args)
      try
        new Function(args, "with($context) { #{code} }")
      catch e
        throw "Twine error: Unable to create function on #{node.nodeName} node with attributes #{stringifyNodeAttributes(node)}"

  requiresRegistry = (args) -> /\$registry/.test(args)

  nodeArrayIndexes = (node) ->
    node.bindingId? && elements[node.bindingId]?.indexes

  arrayPointersForNode = (node, context) ->
    indexes = nodeArrayIndexes(node)
    return {} unless indexes

    result = {}
    for key, index of indexes
      result[key] = context[key][index]
    result

  isKeypath = (value) ->
    value not in ['true', 'false', 'null', 'undefined'] && keypathRegex.test(value)

  fireCustomChangeEvent = (node) ->
    event = document.createEvent('CustomEvent')
    event.initCustomEvent('bindings:change', true, false, {})
    node.dispatchEvent(event)

  Twine.bindingTypes =
    bind: (node, context, definition) ->
      valueProp = valuePropertyForNode(node)
      value = node[valueProp]
      lastValue = undefined
      teardown = undefined

      # Radio buttons only set the value to the node value if checked.
      checkedValueType = node.getAttribute('type') == 'radio'
      fn = wrapFunctionString(definition, '$context,$root,$arrayPointers', node)

      refresh = ->
        newValue = fn.call(node, context, rootContext, arrayPointersForNode(node, context))
        return if newValue == lastValue # return if we can and avoid a DOM operation

        lastValue = newValue
        return if newValue == node[valueProp]

        node[valueProp] = if checkedValueType then newValue == node.value else newValue
        fireCustomChangeEvent(node)

      return {refresh} unless isKeypath(definition)

      refreshContext = ->
        if checkedValueType
          return unless node.checked
          setValue(context, keypath, node.value)
        else
          setValue(context, keypath, node[valueProp])

      keypath = keypathForKey(node, definition)
      twoWayBinding = valueProp != 'textContent' && node.type != 'hidden'

      if keypath[0] == '$root'
        context = rootContext
        keypath = keypath.slice(1)

      if value? && (twoWayBinding || value != '') && !(oldValue = getValue(context, keypath))?
        refreshContext()

      if twoWayBinding
        changeHandler = ->
          return if getValue(context, keypath) == this[valueProp]
          refreshContext()
          Twine.refreshImmediately()
        $(node).on 'input keyup change', changeHandler
        teardown = ->
          $(node).off 'input keyup change', changeHandler

      {refresh, teardown}

    'bind-show': (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$arrayPointers', node)
      lastValue = undefined
      return refresh: ->
        newValue = !fn.call(node, context, rootContext, arrayPointersForNode(node, context))
        return if newValue == lastValue
        $(node).toggleClass('hide', lastValue = newValue)

    'bind-class': (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$arrayPointers', node)
      lastValue = {}
      return refresh: ->
        newValue = fn.call(node, context, rootContext, arrayPointersForNode(node, context))
        for key, value of newValue when !lastValue[key] != !value
          $(node).toggleClass(key, !!value)
        lastValue = newValue

    'bind-attribute': (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$arrayPointers', node)
      lastValue = {}
      return refresh: ->
        newValue = fn.call(node, context, rootContext, arrayPointersForNode(node, context))
        for key, value of newValue when lastValue[key] != value
          $(node).attr(key, value || null)
        lastValue = newValue

    define: (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$registry,$arrayPointers', node)
      object = fn.call(node, context, rootContext, registry, arrayPointersForNode(node, context))
      context[key] = value for key, value of object
      return

    eval: (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$registry,$arrayPointers', node)
      fn.call(node, context, rootContext, registry, arrayPointersForNode(node, context))
      return

  defineArray = (node, context, definition) ->
    fn = wrapFunctionString(definition, '$context,$root', node)
    object = fn.call(node, context, rootContext)

    indexes = {}

    for key, value of object
      context[key] ?= []
      throw "Twine error: expected '#{key}' to be an array" unless context[key] instanceof Array

      indexes[key] = context[key].length
      context[key].push(value)

    indexes

  setupPropertyBinding = (attributeName, bindingName) ->
    booleanProp = attributeName in ['checked', 'indeterminate', 'disabled', 'readOnly']

    Twine.bindingTypes["bind-#{bindingName}"] = (node, context, definition) ->
      fn = wrapFunctionString(definition, '$context,$root,$arrayPointers', node)
      lastValue = undefined
      return refresh: ->
        newValue = fn.call(node, context, rootContext, arrayPointersForNode(node, context))
        newValue = !!newValue if booleanProp
        return if newValue == lastValue
        node[attributeName] = lastValue = newValue

        fireCustomChangeEvent(node) if attributeName == 'checked'

  for attribute in ['placeholder', 'checked', 'indeterminate', 'disabled', 'href', 'title', 'readOnly', 'src']
    setupPropertyBinding(attribute, attribute)

  setupPropertyBinding('innerHTML', 'unsafe-html')

  preventDefaultForEvent = (event) ->
    (event.type == 'submit' || event.currentTarget.nodeName.toLowerCase() == 'a') &&
    Twine.getAttribute(event.currentTarget, 'allow-default') in ['false', false, 0, undefined, null]

  setupEventBinding = (eventName) ->
    Twine.bindingTypes["bind-event-#{eventName}"] = (node, context, definition) ->
      onEventHandler = (event, data) ->
        discardEvent = Twine.shouldDiscardEvent[eventName]?(event)
        if discardEvent || preventDefaultForEvent(event)
          event.preventDefault()

        return if discardEvent

        wrapFunctionString(definition, '$context,$root,$arrayPointers,event,data', node).call(node, context, rootContext, arrayPointersForNode(node, context), event, data)
        Twine.refreshImmediately()
      $(node).on eventName, onEventHandler

      return teardown: ->
        $(node).off eventName, onEventHandler

  for eventName in ['click', 'dblclick', 'mouseenter', 'mouseleave', 'mouseover', 'mouseout', 'mousedown', 'mouseup',
    'submit', 'dragenter', 'dragleave', 'dragover', 'drop', 'drag', 'change', 'keypress', 'keydown', 'keyup', 'input',
    'error', 'done', 'success', 'fail', 'blur', 'focus', 'load', 'paste']
    setupEventBinding(eventName)

  Twine
)

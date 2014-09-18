window.Twine = {}
Twine.shouldDiscardEvent = {}

# Map of node binding ids to objects that describe a node's bindings.
elements = {}

# The number of nodes bound since the last call to Twine.reset().
# Used to determine the next binding id.
nodeCount = 0

# Storage for all bindable data, provided by the caller of Twine.reset().
rootContext = null

keypathRegex = /^[a-z]\w*(\.[a-z]\w*|\[\d+\])*$/i # Tests if a string is a pure keypath.
refreshQueued = false
rootNode = null

# Cleans up all existing bindings and sets the root node and context.
Twine.reset = (newContext, node = document.documentElement) ->
  for bindingsArr in elements
    obj.teardown() for obj in bindingsArr when obj.teardown
  elements = {}

  rootContext = newContext
  rootNode = node
  rootNode.bindingId = nodeCount = 1

  this

Twine.bind = (node = rootNode, context = Twine.context(node)) ->
  bind(context, node, true)

bind = (context, node, forceSaveContext) ->
  if node.bindingId
    Twine.unbind(node)

  for type, binding of Twine.bindingTypes when definition = node.getAttribute(type)
    element = {bindings: []} unless element  # Defer allocation to prevent GC pressure
    fn = binding(node, context, definition, element)
    element.bindings.push(fn) if fn

  if newContextKey = node.getAttribute('context')
    keypath = keypathForKey(newContextKey)
    if keypath[0] == '$root'
      context = rootContext
      keypath = keypath.slice(1)
    context = getValue(context, keypath) || setValue(context, keypath, {})

  if element || newContextKey || forceSaveContext
    (element ?= {}).childContext = context
    elements[node.bindingId ?= ++nodeCount] = element

  # IE and Safari don't support node.children for DocumentFragment and SVGElement nodes.
  # If the element supports children we continue to traverse the children, otherwise
  # we stop traversing that subtree.
  # https://developer.mozilla.org/en-US/docs/Web/API/ParentNode.children
  # As a result, Twine are unsupported within DocumentFragment and SVGElement nodes.
  bind(context, childNode) for childNode in (node.children || [])
  Twine.count = nodeCount
  Twine

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
    if (id = node.bindingId) && (context = elements[id]?.childContext)
      return context
    node = node.parentNode if child

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

valueAttributeForNode = (node) ->
  name = node.nodeName.toLowerCase()
  if name in ['input', 'textarea', 'select']
    if node.getAttribute('type') in ['checkbox', 'radio'] then 'checked' else 'value'
  else
    'textContent'

keypathForKey = (key) ->
  keypath = []
  for key in key.split('.')
    if (start = key.indexOf('[')) != -1
      keypath.push(key.substr(0, start))
      key = key.substr(start)

      while (end = key.indexOf(']')) != -1
        keypath.push(parseInt(key.substr(1, end), 10))
        key = key.substr(end + 1)
    else
      keypath.push(key)
  keypath

getValue = (object, keypath) ->
  object = object[key] for key in keypath when object?
  object

setValue = (object, keypath, value) ->
  [keypath..., lastKey] = keypath
  for key in keypath
    object = object[key] ?= {}
  object[lastKey] = value

wrapFunctionString = (code, args) ->
  if isKeypath(code) && keypath = keypathForKey(code)
    if keypath[0] == '$root'
      ($context, $root) -> getValue($root, keypath)
    else
      ($context, $root) -> getValue($context, keypath)
  else
    new Function(args, "with($context) { return #{code} }")

isKeypath = (value) ->
  value not in ['true', 'false', 'null', 'undefined'] and keypathRegex.test(value)

fireCustomChangeEvent = (node) ->
  event = document.createEvent('CustomEvent')
  event.initCustomEvent('bindings:change', true, false, {})
  node.dispatchEvent(event)

Twine.bindingTypes =
  bind: (node, context, definition) ->
    valueAttribute = valueAttributeForNode(node)
    value = node[valueAttribute]
    lastValue = undefined
    teardown = undefined

    # Radio buttons only set the value to the node value if checked.
    checkedValueType = node.getAttribute('type') == 'radio'
    fn = wrapFunctionString(definition, '$context,$root')

    refresh = ->
      newValue = fn.call(node, context, rootContext)
      return if newValue == lastValue

      lastValue = newValue
      return if newValue == node[valueAttribute]

      node[valueAttribute] = if checkedValueType then newValue == node.value else newValue
      fireCustomChangeEvent(node)

    return {refresh} unless isKeypath(definition)

    refreshContext = ->
      if checkedValueType
        return unless node.checked
        setValue(context, keypath, node.value)
      else
        setValue(context, keypath, node[valueAttribute])

    keypath = keypathForKey(definition)
    twoWayBinding = valueAttribute != 'textContent' && node.type != 'hidden'

    if keypath[0] == '$root'
      context = rootContext
      keypath = keypath.slice(1)

    if value? && (twoWayBinding || value != '') && !(oldValue = getValue(context, keypath))?
      refreshContext()

    if twoWayBinding
      changeHandler = ->
        return if getValue(context, keypath) == this[valueAttribute]
        refreshContext()
        Twine.refreshImmediately()
      node.addEventListener(eventKey, changeHandler) for eventKey in ['input', 'keyup', 'change']
      teardown = ->
        node.removeEventListener(eventKey, changeHandler) for eventKey in ['input', 'keyup', 'change']

    {refresh, teardown}

  'bind-show': (node, context, definition) ->
    fn = wrapFunctionString(definition, '$context,$root')
    lastValue = undefined
    return refresh: ->
      newValue = !fn.call(node, context, rootContext)
      return if newValue == lastValue
      $(node).toggleClass('hide', lastValue = newValue)

  'bind-class': (node, context, definition) ->
    fn = wrapFunctionString(definition, '$context,$root')
    lastValue = {}
    return refresh: ->
      newValue = fn.call(node, context, rootContext)
      for key, value of newValue when !lastValue[key] != !value
        $(node).toggleClass(key, !!value)
      lastValue = newValue

  define: (node, context, definition) ->
    fn = wrapFunctionString(definition, '$context,$root')
    object = fn.call(node, context, rootContext)
    context[key] = value for key, value of object
    return

setupAttributeBinding = (attributeName, bindingName) ->
  booleanAttribute = attributeName in ['checked', 'disabled', 'readOnly']

  Twine.bindingTypes["bind-#{bindingName}"] = (node, context, definition) ->
    fn = wrapFunctionString(definition, '$context,$root')
    lastValue = undefined
    return refresh: ->
      newValue = fn.call(node, context, rootContext)
      newValue = !!newValue if booleanAttribute
      return if newValue == lastValue
      node[attributeName] = lastValue = newValue

for attribute in ['placeholder', 'checked', 'disabled', 'href', 'title', 'readOnly']
  setupAttributeBinding(attribute, attribute)

setupAttributeBinding('innerHTML', 'unsafe-html')

preventDefaultForEvent = (event) ->
  (event.type == 'submit' || event.currentTarget.nodeName.toLowerCase() == 'a') && event.currentTarget.getAttribute('allow-default') != '1'

setupEventBinding = (eventName) ->
  Twine.bindingTypes["bind-event-#{eventName}"] = (node, context, definition) ->
    onEventHandler = (event, data) ->
      discardEvent = Twine.shouldDiscardEvent[eventName]?(event)
      if discardEvent || preventDefaultForEvent(event)
        event.preventDefault()

      return if discardEvent

      wrapFunctionString(definition, '$context,$root,event,data').call(node, context, rootContext, event, data)
      Twine.refreshImmediately()
    $(node).on eventName, onEventHandler

    return teardown: ->
      $(node).off eventName, onEventHandler

for eventName in ['click', 'dblclick', 'mousedown', 'mouseup', 'submit', 'dragenter', 'dragleave', 'dragover', 'drop', 'drag', 'change', 'keypress', 'keydown', 'keyup', 'input', 'error', 'done', 'fail', 'blur', 'focus']
  setupEventBinding(eventName)

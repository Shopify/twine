require('pbind')

suite "Twine", ->
  setupView = (html, context) ->
    rootNode.innerHTML = html
    Twine.reset(context, rootNode).bind().refreshImmediately()
    rootNode.children[0]

  triggerEvent = (node, eventName) ->
    event = document.createEvent("HTMLEvents")
    event.initEvent eventName, false, true
    node.dispatchEvent event

  rootNode = undefined
  setup ->
    @clock.tick 100
    rootNode = document.createElement("div")

  suite "bind attribute", ->
    test "should bind basic keypaths", ->
      testView = "<div bind=\"key\"></div>"
      node = setupView(testView, key: "value")
      assert.equal node.innerHTML, "value"

    test "should bind compound keypaths", ->
      testView = "<div bind=\"key.nested.more\"></div>"
      node = setupView(testView, key: {nested: { more: "value"}})
      assert.equal node.innerHTML, "value"

    test "should bind array accessor keypaths", ->
      testView = "<input bind=\"key[0]\">"
      node = setupView(testView, context = key: ["value"])
      assert.equal node.value, "value"

      context.key[0] = "new"
      Twine.refreshImmediately()
      assert.equal node.value, "new"

      node.value = "value"
      triggerEvent node, "change"
      assert.equal node.value, "value"

    test "should bind 'true' keyword keypaths", ->
      testView = "<div bind=\"true\"></div>"
      node = setupView(testView, key: "true")
      assert.equal node.innerHTML, "true"

    test "should bind 'false' keyword keypaths", ->
      testView = "<div bind=\"false\"></div>"
      node = setupView(testView, key: "false")
      assert.equal node.innerHTML, "false"

    test "should bind undefined keyword keypath", ->
      testView = "<div bind=\"undefined\"></div>"
      node = setupView(testView, key: "undefined")
      assert.equal node.innerHTML, ""

    test "should bind null keyword keypath", ->
      testView = "<div bind=\"null\"></div>"
      node = setupView(testView, key: "null")
      assert.equal node.innerHTML, ""

    test "should load data from the DOM if not defined", ->
      testView = "<div bind=\"key.nested\">value</div>"
      setupView(testView, context = {})
      assert.equal context.key.nested, "value"

    test "should set the value of input[type=text] elements", ->
      testView = "<input type=\"text\" bind=\"key\">"
      node = setupView(testView, context = key: "value")
      assert.equal node.value, "value"

      context.key = "new"
      Twine.refreshImmediately()
      assert.equal node.value, "new"

    test "should set the checked value of input[type=checkbox] elements", ->
      testView = "<input type=\"checkbox\" bind=\"key\">"
      node = setupView(testView, context = key: "value")
      assert.isTrue node.checked

      context.key = ""
      Twine.refreshImmediately()
      assert.isFalse node.checked

    test "should set the checked state of input[type=radio] elements", ->
      testView = "<input type=\"radio\" bind=\"key\" value=\"one\"><input type=\"radio\" bind=\"key\" value=\"two\">"
      setupView(testView, context = key: "two")
      assert.isFalse rootNode.children[0].checked
      assert.isTrue rootNode.children[1].checked

      context.key = "one"
      Twine.refreshImmediately()
      assert.isTrue rootNode.children[0].checked
      assert.isFalse rootNode.children[1].checked

    test "should get the value of input[type=radio] elements", ->
      testView = "<input type=\"radio\" name=\"group\" bind=\"key\" value=\"one\">" + "<input type=\"radio\" name=\"group\" bind=\"key\" value=\"two\" checked>"
      setupView(testView, context = {})
      assert.equal context.key, "two"

      rootNode.children[0].checked = true
      triggerEvent rootNode.children[0], "change"
      assert.equal context.key, "one"

    test "should get the selected state of the right child in select elements", ->
      testView = """
                  <select bind="key">
                    <option value="one">one</option>
                    <option value="two" selected>two</option>
                    <option value="three">three</option>
                  </select>
                 """

      setupView(testView, context = {})
      select = rootNode.children[0]
      options = select.children

      assert.equal context.key, 'two'

      options[0].selected = true
      triggerEvent select, 'change'
      assert.equal context.key, 'one'

      options[2].selected = true
      triggerEvent select, 'change'
      assert.equal context.key, 'three'

    test "should set the selected state of the right child in select elements", ->
      testView = """
                  <select bind="key">
                    <option value="one">one</option>
                    <option value="two" selected>two</option>
                    <option value="three">three</option>
                  </select>
                 """

      setupView(testView, context = {})
      select = rootNode.children[0]
      options = select.children

      assert.isTrue options[1].selected

      context.key = 'one'
      Twine.refreshImmediately()
      assert.isTrue options[0].selected

      context.key = 'three'
      Twine.refreshImmediately()
      assert.isTrue options[2].selected

    test "should work with arbitrary javascript", ->
      testView = "<div bind=\"key * 2\"></div>"
      node = setupView(testView, key: 4)
      assert.equal node.innerHTML, "8"

    test "should work with arbitrary javascript that looks like a keypath", ->
      testView = "<div bind=\"2.34\"></div>"
      node = setupView(testView, {})
      assert.equal node.innerHTML, "2.34"

    test "should escape weird characters", ->
      testView = "<div bind=\"key\"></div>"
      node = setupView(testView, key: "<script>")
      assert.equal node.innerHTML, "&lt;script&gt;"

  suite "bind-show attribute", ->
    test "should apply the \"hide\" class when falsy", ->
      testView = "<div bind-show=\"key\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should apply the \"hide\" class when false", ->
      testView = "<div bind-show=\"false\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should apply the \"hide\" class when undefined", ->
      testView = "<div bind-show=\"undefined\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should not apply any class when truthy", ->
      testView = "<div bind-show=\"key\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, ""

    test "should not apply any class when is 'true'", ->
      testView = "<div bind-show=\"true\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, ""

  suite "bind-class attribute", ->
    test "should apply the given classes when truthy", ->
      testView = "<div bind-class=\"{cls: key, cls2: false}\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, "cls"

  suite "bind-attribute attribute", ->
    test "should apply the given attribute when truthy", ->
      testView = "<div bind-attribute=\"{a: key, b: false, c: 0, d: null, e: undefined}\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.getAttribute('a'), 'true'
      assert.equal node.getAttribute('b'), 'false'
      assert.equal node.getAttribute('c'), '0'
      assert.isFalse node.hasAttribute('d')
      assert.isFalse node.hasAttribute('e')

  suite "bind-checked attribute", ->
    test "should set the checked attribute", ->
      testView = "<input type=\"checkbox\" bind-checked=\"key\">"
      node = setupView(testView, context = key: true)
      assert.isTrue node.checked

      context.key = false
      Twine.refreshImmediately()
      assert.isFalse node.checked

    test "should fire bindings:change on check change", ->
      testView = "<input type=\"checkbox\" bind-checked=\"key\">"
      node = setupView(testView, context = key: true)

      node.addEventListener('bindings:change', eventSpy = @spy())

      context.key = false
      Twine.refreshImmediately()

      assert.ok eventSpy.called

  suite "bind-placeholder attribute", ->
    test "should set the placeholder attribute", ->
      testView = "<div bind-placeholder=\"key\">"
      node = setupView(testView, context = key: "val")
      assert.equal node.placeholder, "val"

      context.key = "other"
      Twine.refreshImmediately()
      assert.equal node.placeholder, "other"

  suite "bind-readOnly attribute", ->
    test "should set the readonly attribute", ->
      testView = "<input type=\"text\" bind-readonly=\"key\">"
      node = setupView(testView, context = key: true)
      assert.isTrue node.readOnly

      context.key = false
      Twine.refreshImmediately()
      assert.isFalse node.readOnly

  suite "bind-unsafe-html attribute", ->
    test "should set the innerHTML of the node", ->
      testView = "<div bind-unsafe-html=\"key\"></div>"
      node = setupView(testView, key: "&amp;")
      assert.equal node.innerHTML, "&amp;"

  suite "bind-src attribute", ->
    test "should set the src of the node", ->
      testView = '<img bind-src="key"></div>'
      node = setupView(testView, key: "image.jpg")
      assert.match node.src, /\/image\.jpg$/

  suite "bind-event-* attribute", ->
    test "should not run the handler when not allowed", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.shouldDiscardEvent.click = -> true

      $(node).click()
      assert.equal context.fn.callCount, 0
      Twine.shouldDiscardEvent = {}

    test "should pass along data if present", ->
      testView = "<form bind-event-submit=\"fn(data)\"></form>"
      node = setupView(testView, context = fn: @spy())
      data = {test: 'bla123'}

      $(node).trigger 'submit', data

      assert.isTrue context.fn.calledOnce
      assert.isTrue context.fn.calledWith(data)

    test "unbind should remove event listener", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())

      assert node.bindingId
      Twine.unbind(node)
      assert.isUndefined node.bindingId

      $(node).click()
      assert.equal context.fn.callCount, 0

  suite "bind-event-click attribute", ->
    test "should run the handler on click", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())

      $(node).click()
      assert.isTrue context.fn.calledOnce

  suite "bind-event-submit attribute", ->
    test "should run the handler on submit", ->
      testView = "<form bind-event-submit=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "submit"
      assert.isTrue context.fn.calledOnce

  suite "bind-event-change attribute", ->
    test "should run the handler on change", ->
      testView = "<input bind-event-change=\"fn()\" value=\"old\">"
      node = setupView(testView, context = fn: @spy())
      node.value = "new"

      triggerEvent node, "change"
      assert.isTrue context.fn.calledOnce

  suite "bind-event-error attribute", ->
    test "should run the handler on change", ->
      testView = "<img src=\"\" bind-event-error=\"fn()\">"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "error"
      assert.isTrue context.fn.calledOnce

  suite "bind-event-done attribute", ->
    test "should run the handler on done event", ->
      testView = "<form bind-event-done=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "done"
      assert.isTrue context.fn.calledOnce

  suite "bind-event-fail attribute", ->
    test "should run the handler on fail event", ->
      testView = "<form bind-event-fail=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "fail"
      assert.isTrue context.fn.calledOnce

  suite "define attribute", ->
    test "should mix in the given keys", ->
      testView = "<div define=\"{key: 'value', key2: 'value2'}\"></div>"
      setupView(testView, context = {})

      assert.equal context.key, "value"
      assert.equal context.key2, "value2"

    test "should throw a helpful error if trying to define improperly", ->
      testView = "<div define=\"{key: 'value', key2: 'value2\"></div>"
      assert.throw ->
        setupView(testView, context = {})
      , 'Twine error: Unable to create function on DIV node with attributes define=\'{key: \'value\', key2: \'value2\''

  suite "refresh", ->
    test "should defer calls and refresh once", ->
      setupView("", {})
      @spy(Twine, "refreshImmediately")

      Twine.refresh()
      Twine.refresh()
      Twine.refresh()
      assert.isFalse Twine.refreshImmediately.called

      @clock.tick 100
      assert.isTrue Twine.refreshImmediately.calledOnce

    test "should happen when a bound element is clicked", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, fn: ->)
      @spy(Twine, "refreshImmediately")

      $(node).click()
      @clock.tick 100
      assert.isTrue Twine.refreshImmediately.calledOnce

    test "should happen when a bound input element changes", ->
      testView = "<input bind=\"key\">"
      node = setupView(testView, {})
      @spy Twine, "refreshImmediately"

      node.value = "new"
      triggerEvent node, "change"
      @clock.tick 100
      assert.isTrue Twine.refreshImmediately.calledOnce

    test "should not happen if the value did not change", ->
      testView = "<input bind=\"key\">"
      node = setupView(testView, {})
      @spy Twine, "refreshImmediately"

      triggerEvent node, "change"
      @clock.tick 100
      assert.isFalse Twine.refreshImmediately.called

  suite "bind", ->
    test "should descend contexts", ->
      inner = key: "value"
      testView = "<div context=\"inner\"><div bind=\"key\"></div></div>"
      node = setupView(testView, inner: inner).children[0]

      assert.equal node.innerHTML, "value"
      assert.equal Twine.context(node), inner

    test "should create the context if it doesn't exist", ->
      testView = "<div context=\"inner\"><div bind=\"key\">value</div></div>"
      setupView(testView, context = {})
      assert.equal context.inner.key, "value"

    test "should force the node parameter to have its context stored", ->
      testView = "<div></div>"
      node = setupView(testView, context = {})

      Twine.bind(node)
      assert.equal Twine.context(node), context

    test "should fire custom bindings:change", ->
      testView = '<input type="text" bind="name">'
      node = setupView(testView, context = {name: "foo"})

      node.addEventListener('bindings:change', eventSpy = @spy())

      context.name = "bar"
      Twine.refreshImmediately()
      assert.ok eventSpy.called

    test "should not bind on hidden fields", ->
      testView = '<input type="hidden" bind="name">'
      node = setupView(testView, context = {name: "foo"})

      node.value = "new"
      triggerEvent node, "change"
      assert.equal context.name, "foo"

    test "should not bind on previously binded nodes", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.bind()

      $(node).click()
      assert.isTrue context.fn.calledOnce

  suite "Twine.register", ->
    test "callbacks are passed the context they were defined within", ->
      class window.CallbackTestThing
        called: 0
        constructor: ->
          Twine.register =>
            @called++

      testView = '''
      <div id="outerContext" context="outer" define="{outer: new CallbackTestThing}">
        <div id="innerContext" context="inner" define="{inner: new CallbackTestThing}"></div>
      </div>
      '''

      node = setupView(testView, context = {})

      assert.equal 1, Twine.context(node).outer.called
      assert.equal 1, Twine.context(node).outer.inner.called

    test "callbacks can be defined on the rootContext", ->
      called = false
      Twine.register(-> called = true)

      setupView("<div></div>", context = {})
      assert.isTrue called

    test "rebind calls callbacks again", ->
      class window.CallbackTestThing
        @called: 0
        called: 0
        constructor: ->
          Twine.register =>
            @called++
            @constructor.called++

      testView = '<div context="inner" define="{inner: new CallbackTestThing}"></div>'
      node = setupView(testView, inner = {})

      assert.equal 1, Twine.context(node).inner.called
      assert.equal 1, Twine.context(node).inner.constructor.called

      Twine.bind()

      assert.equal 1, Twine.context(node).inner.called
      assert.equal 2, Twine.context(node).inner.constructor.called

    test "run the callback even if bindings have finished", ->
      called = false

      setupView("<div></div>", context = {})
      assert.isFalse called

      Twine.register(-> called = true)
      assert.isTrue called

  suite "reset", ->
    test "should set up the root node", ->
      Twine.reset(context = {}, rootNode)

      assert.equal rootNode.bindingId, 1
      assert.equal Twine.context(rootNode), context

    test "should teardown all elements in memory", ->
      testView = "<div bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.bind(node)
      Twine.reset({}, rootNode)

      $(node).click()
      assert.equal context.fn.callCount, 0

  test "context should return the node's context", ->
    testView = '<div context="inner"><div context="inner"></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.context(node), context
    assert.equal Twine.context(node.firstChild), context.inner

  test "childContext should return the node's childrens' context", ->
    testView = '<div context="inner"><div context="inner"></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.childContext(node), context.inner
    assert.equal Twine.childContext(node.firstChild), context.inner.inner

  test "contextKey should return the key", ->
    testView = '<div context="inner"><div context="inner"><div></div></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.contextKey(node), ''
    assert.equal Twine.contextKey(node.firstChild), 'inner'
    assert.equal Twine.contextKey(node.firstChild.firstChild), 'inner.inner'

  test "contextKey should accept an extra context to use as the last key element", ->
    testView = '<div context="inner"><div context="inner"><div></div></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.contextKey(node.firstChild, context.inner.inner), 'inner.inner'

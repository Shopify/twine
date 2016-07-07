Twine = require('../dist/twine')

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

  suite "data-bind attribute", ->
    test "should bind basic keypaths", ->
      testView = "<div data-bind=\"key\"></div>"
      node = setupView(testView, key: "value")
      assert.equal node.innerHTML, "value"

    test "should bind compound keypaths", ->
      testView = "<div data-bind=\"key.nested.more\"></div>"
      node = setupView(testView, key: {nested: { more: "value"}})
      assert.equal node.innerHTML, "value"

    test "should bind array accessor keypaths", ->
      testView = "<input data-bind=\"key[0]\">"
      node = setupView(testView, context = key: ["value"])
      assert.equal node.value, "value"

      context.key[0] = "new"
      Twine.refreshImmediately()
      assert.equal node.value, "new"

      node.value = "value"
      triggerEvent node, "change"
      assert.equal node.value, "value"

    test "should bind 'true' keyword keypaths", ->
      testView = "<div data-bind=\"true\"></div>"
      node = setupView(testView, key: "true")
      assert.equal node.innerHTML, "true"

    test "should bind 'false' keyword keypaths", ->
      testView = "<div data-bind=\"false\"></div>"
      node = setupView(testView, key: "false")
      assert.equal node.innerHTML, "false"

    test "should bind undefined keyword keypath", ->
      testView = "<div data-bind=\"undefined\"></div>"
      node = setupView(testView, key: "undefined")
      assert.equal node.innerHTML, ""

    test "should bind null keyword keypath", ->
      testView = "<div data-bind=\"null\"></div>"
      node = setupView(testView, key: "null")
      assert.equal node.innerHTML, ""

    test "should load data from the DOM if not defined", ->
      testView = "<div data-bind=\"key.nested\">value</div>"
      setupView(testView, context = {})
      assert.equal context.key.nested, "value"

    test "should set the value of input[type=text] elements", ->
      testView = "<input type=\"text\" data-bind=\"key\">"
      node = setupView(testView, context = key: "value")
      assert.equal node.value, "value"

      context.key = "new"
      Twine.refreshImmediately()
      assert.equal node.value, "new"

    test "should set the checked value of input[type=checkbox] elements", ->
      testView = "<input type=\"checkbox\" data-bind=\"key\">"
      node = setupView(testView, context = key: "value")
      assert.isTrue node.checked

      context.key = ""
      Twine.refreshImmediately()
      assert.isFalse node.checked

    test "should set the checked state of input[type=radio] elements", ->
      testView = "<input type=\"radio\" data-bind=\"key\" value=\"one\"><input type=\"radio\" data-bind=\"key\" value=\"two\">"
      setupView(testView, context = key: "two")
      assert.isFalse rootNode.children[0].checked
      assert.isTrue rootNode.children[1].checked

      context.key = "one"
      Twine.refreshImmediately()
      assert.isTrue rootNode.children[0].checked
      assert.isFalse rootNode.children[1].checked

    test "should get the value of input[type=radio] elements", ->
      testView = "<input type=\"radio\" name=\"group\" data-bind=\"key\" value=\"one\">" + "<input type=\"radio\" name=\"group\" data-bind=\"key\" value=\"two\" checked>"
      setupView(testView, context = {})
      assert.equal context.key, "two"

      rootNode.children[0].checked = true
      triggerEvent rootNode.children[0], "change"
      assert.equal context.key, "one"

    test "should get the selected state of the right child in select elements", ->
      testView = """
                  <select data-bind="key">
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
                  <select data-bind="key">
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
      testView = "<div data-bind=\"key * 2\"></div>"
      node = setupView(testView, key: 4)
      assert.equal node.innerHTML, "8"

    test "should work with arbitrary javascript that looks like a keypath", ->
      testView = "<div data-bind=\"2.34\"></div>"
      node = setupView(testView, {})
      assert.equal node.innerHTML, "2.34"

    test "should escape weird characters", ->
      testView = "<div data-bind=\"key\"></div>"
      node = setupView(testView, key: "<script>")
      assert.equal node.innerHTML, "&lt;script&gt;"

    test "should be the first binding to run on change event", ->
      testView = "<input type=\"text\" bind-event-change=\"eventFunc()\" data-bind=\"val\">"
      context = {
        val: 1,
        eventFunc: () -> this.val = this.val * 2
      }
      node = setupView(testView, context)
      node.value = 2
      triggerEvent node, "change"

      assert.equal context.val, 4

    # test "should be the first binding to run on input event", ->
    #   testView = "<input type=\"text\" bind-event-input=\"eventFunc()\" data-bind=\"bindFunc()\">"
    #   node = setupView(testView, context = {
    #     eventFunc: @spy(),
    #     bindFunc: @spy()
    #   })
    #   context.eventFunc.reset()
    #   context.bindFunc.reset()
    #   triggerEvent node, "input"
    #   sinon.assert.callOrder context.bindFunc, context.eventFunc

  suite "data-bind-show attribute", ->
    test "should apply the \"hide\" class when falsy", ->
      testView = "<div data-bind-show=\"key\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should apply the \"hide\" class when false", ->
      testView = "<div data-bind-show=\"false\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should apply the \"hide\" class when undefined", ->
      testView = "<div data-bind-show=\"undefined\"></div>"
      node = setupView(testView, key: false)
      assert.equal node.className, "hide"

    test "should not apply any class when truthy", ->
      testView = "<div data-bind-show=\"key\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, ""

    test "should not apply any class when is 'true'", ->
      testView = "<div data-bind-show=\"true\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, ""

  suite "data-bind-class attribute", ->
    test "should apply the given classes when truthy", ->
      testView = "<div data-bind-class=\"{cls: key, cls2: false}\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.className, "cls"

  suite "data-bind-attribute attribute", ->
    test "should apply the given attribute when truthy", ->
      testView = "<div data-bind-attribute=\"{a: key, b: false, c: 0, d: null, e: undefined, f: function() { return true }, g: '0', h: 'false'}\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.getAttribute('a'), 'true'
      assert.isFalse node.hasAttribute('b')
      assert.isFalse node.hasAttribute('c')
      assert.isFalse node.hasAttribute('d')
      assert.isFalse node.hasAttribute('e')
      assert.equal node.getAttribute('f'), 'true'
      assert.equal node.getAttribute('g'), '0'
      assert.equal node.getAttribute('h'), 'false'

  suite "data-bind-indeterminate attribute", ->
    test "should set the indeterminate attribute", ->
      testView = "<input type=\"checkbox\" data-bind-indeterminate=\"key\">"
      node = setupView(testView, context = key: true)
      assert.isTrue node.indeterminate

      context.key = false
      Twine.refreshImmediately()
      assert.isFalse node.indeterminate

      context.key = null
      Twine.refreshImmediately()
      assert.isFalse node.indeterminate

      context.key = undefined
      Twine.refreshImmediately()
      assert.isFalse node.indeterminate

  suite "data-bind-checked attribute", ->
    test "should set the checked attribute", ->
      testView = "<input type=\"checkbox\" data-bind-checked=\"key\">"
      node = setupView(testView, context = key: true)
      assert.isTrue node.checked

      context.key = false
      Twine.refreshImmediately()
      assert.isFalse node.checked

    test "should fire bindings:change on check change", ->
      testView = "<input type=\"checkbox\" data-bind-checked=\"key\">"
      node = setupView(testView, context = key: true)

      node.addEventListener('bindings:change', eventSpy = @spy())

      context.key = false
      Twine.refreshImmediately()

      assert.ok eventSpy.called

  suite "data-bind-placeholder attribute", ->
    test "should set the placeholder attribute", ->
      testView = "<div data-bind-placeholder=\"key\">"
      node = setupView(testView, context = key: "val")
      assert.equal node.placeholder, "val"

      context.key = "other"
      Twine.refreshImmediately()
      assert.equal node.placeholder, "other"

  suite "data-bind-readOnly attribute", ->
    test "should set the readonly attribute", ->
      testView = "<input type=\"text\" data-bind-readonly=\"key\">"
      node = setupView(testView, context = key: true)
      assert.isTrue node.readOnly

      context.key = false
      Twine.refreshImmediately()
      assert.isFalse node.readOnly

  suite "data-bind-unsafe-html attribute", ->
    test "should set the innerHTML of the node", ->
      testView = "<div data-bind-unsafe-html=\"key\"></div>"
      node = setupView(testView, key: "&amp;")
      assert.equal node.innerHTML, "&amp;"

  suite "data-bind-src attribute", ->
    test "should set the src of the node", ->
      testView = '<img data-bind-src="key"></div>'
      node = setupView(testView, key: "image.jpg")
      assert.match node.src, /\/image\.jpg$/

  suite "data-bind-event-* attribute", ->
    test "should not run the handler when not allowed", ->
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.shouldDiscardEvent.click = -> true

      $(node).click()
      assert.equal context.fn.callCount, 0
      Twine.shouldDiscardEvent = {}

    test "should pass along data if present", ->
      testView = "<form data-bind-event-submit=\"fn(data)\"></form>"
      node = setupView(testView, context = fn: @spy())
      data = {test: 'bla123'}

      $(node).trigger 'submit', data

      assert.isTrue context.fn.calledOnce
      assert.isTrue context.fn.calledWith(data)

    test "unbind should remove event listener", ->
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())

      assert node.bindingId
      Twine.unbind(node)
      assert.isUndefined node.bindingId

      $(node).click()
      assert.equal context.fn.callCount, 0

  suite "data-bind-event-click attribute", ->
    test "should run the handler on click", ->
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())

      $(node).click()
      assert.isTrue context.fn.calledOnce

  suite "data-bind-event-submit attribute", ->
    test "should run the handler on submit", ->
      testView = "<form data-bind-event-submit=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "submit"
      assert.isTrue context.fn.calledOnce

  suite "data-bind-event-change attribute", ->
    test "should run the handler on change", ->
      testView = "<input data-bind-event-change=\"fn()\" value=\"old\">"
      node = setupView(testView, context = fn: @spy())
      node.value = "new"

      triggerEvent node, "change"
      assert.isTrue context.fn.calledOnce

  suite "data-bind-event-error attribute", ->
    test "should run the handler on change", ->
      testView = "<img src=\"\" data-bind-event-error=\"fn()\">"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "error"
      assert.isTrue context.fn.calledOnce

  suite "data-bind-event-done attribute", ->
    test "should run the handler on done event", ->
      testView = "<form data-bind-event-done=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "done"
      assert.isTrue context.fn.calledOnce

  suite "data-bind-event-fail attribute", ->
    test "should run the handler on fail event", ->
      testView = "<form data-bind-event-fail=\"fn()\"></form>"
      node = setupView(testView, context = fn: @spy())

      triggerEvent node, "fail"
      assert.isTrue context.fn.calledOnce

  suite "data-define attribute", ->
    test "should mix in the given keys", ->
      testView = "<div data-define=\"{key: 'value', key2: 'value2'}\"></div>"
      setupView(testView, context = {})

      assert.equal context.key, "value"
      assert.equal context.key2, "value2"

    test "should throw a helpful error if trying to define improperly", ->
      testView = "<div data-define=\"{key: 'value', key2: 'value2\"></div>"
      assert.throw ->
        setupView(testView, context = {})
      , 'Twine error: Unable to create function on DIV node with attributes data-define="{key: \'value\', key2: \'value2"'

  suite 'data-define-array attribute', ->
    test 'should mix in the given keys into an array', ->
      testView = '''
        <div data-define-array="{key: 'val'}"></div>
        <div data-define-array="{key: 'other val'}"></div>
      '''

      setupView(testView, context = {})
      assert.deepEqual ['val', 'other val'], context.key

    test 'should throw an exception if the key exists but is not an array', ->
      testView = '<div data-define-array="{key: \'val\'}"></div>'

      assert.throw ->
        setupView(testView, context = {key: "foo"})
      , "Twine error: expected 'key' to be an array"

    test 'should be able to access the correct position in the array from inside the element, with or without a context', ->
      testView = '''
        <div>
          <div data-define-array="{key: {value: 'val'}, otherKey: {value: 'other val'}}">
            <span bind="key.value"></span>
            <span bind="otherKey.value"></span>
          </div>
          <div data-define-array="{key: {value: 'third val'}}" context="key">
            <span bind="value"></span>
          </div>
          <div data-define-array="{key: {value: 'fourth val'}, otherKey: {value: 'fifth val'}}">
            <span bind="key.value"></span>
            <span bind="otherKey.value"></span>
          </div>
        </div>
      '''

      node = setupView(testView, context = {})
      assert.equal 'val',         node.children[0].children[0].textContent
      assert.equal 'other val',   node.children[0].children[1].textContent
      assert.equal 'third val',   node.children[1].children[0].textContent
      assert.equal 'fourth val',  node.children[2].children[0].textContent
      assert.equal 'fifth val',   node.children[2].children[1].textContent

    test 'should correctly set up newly bound elements with the contexts of defined arrays', ->
      testView = '''
        <div>
          <div data-define-array="{key: {value: 'val'}}"></div>
          <div data-define-array="{key: {value: 'other val'}}">
            <div>
            </div>
          </div>
        </div
      '''

      node = setupView(testView, context = {})

      span = document.createElement('span')
      span.setAttribute('data-bind', "key.value")
      node.children[0].appendChild(span)

      span2 = document.createElement('span')
      span2.setAttribute('data-bind', "key.value")
      node.children[1].children[0].appendChild(span2)

      Twine.bind(span)
      Twine.bind(span2)
      Twine.refreshImmediately()

      assert.equal 'val', span.textContent
      assert.equal 'other val', span2.textContent

    test 'should work with nested arrays', ->
      testView = '''
        <div>
          <div data-define-array="{key: {value: 5}}">
            <div data-define-array="{nested: {value: 50}}">
              <span bind="key.value"></span>
              <span bind="nested.value"></span>
            </div>
            <div data-define-array="{nested: {value: 75}}">
              <span bind="key.value"></span>
              <span bind="nested.value"></span>
            </div>
          </div>
          <div data-define-array="{key: {value: 10}}">
            <div data-define-array="{nested: {value: 100}}">
              <span bind="key.value"></span>
              <span bind="nested.value"></span>
            </div>
            <div data-define-array="{nested: {value: 125}}">
              <span bind="key.value"></span>
              <span bind="nested.value"></span>
            </div>
          </div>
        </div>
      '''

      node = setupView(testView, context = {})

      assert.equal "5",   node.children[0].children[0].children[0].textContent
      assert.equal "50",  node.children[0].children[0].children[1].textContent
      assert.equal "5",   node.children[0].children[1].children[0].textContent
      assert.equal "75",  node.children[0].children[1].children[1].textContent
      assert.equal "10",  node.children[1].children[0].children[0].textContent
      assert.equal "100", node.children[1].children[0].children[1].textContent
      assert.equal "10",  node.children[1].children[1].children[0].textContent
      assert.equal "125", node.children[1].children[1].children[1].textContent

    test 'only the first key in a keypath gets treated like an array', ->
      testView = '''
        <div data-define-array="{key: {value: 5}, value: 25}">
          <span bind="key.value"></span>
        </div>
      '''

      node = setupView(testView, context = {})

      assert.equal "5", node.children[0].textContent

    test 'should work with function calls and nested arrays', ->
      testView = '''
        <div>
          <div data-define-array="{key: {foo: function(){ return 5; }}}">
            <div data-define-array="{nested: {bar: function(){ return 50; }}}">
              <span bind="key.foo()"></span>
              <span bind="nested.bar()"></span>
            </div>
            <div data-define-array="{nested: {bar: function(){ return 75; }}}">
              <span bind="key.foo()"></span>
              <span bind="nested.bar()"></span>
            </div>
          </div>
          <div data-define-array="{key: {foo: function(){ return 10; }}}">
            <div data-define-array="{nested: {bar: function(){ return 100; }}}">
              <span bind="key.foo()"></span>
              <span bind="nested.bar()"></span>
            </div>
            <div data-define-array="{nested: {bar: function(){ return 125; }}}">
              <span bind="key.foo()"></span>
              <span bind="nested.bar()"></span>
            </div>
          </div>
        </div>
      '''

      node = setupView(testView, context = {})
      assert.equal "5",   node.children[0].children[0].children[0].textContent
      assert.equal "50",  node.children[0].children[0].children[1].textContent
      assert.equal "5",   node.children[0].children[1].children[0].textContent
      assert.equal "75",  node.children[0].children[1].children[1].textContent
      assert.equal "10",  node.children[1].children[0].children[0].textContent
      assert.equal "100", node.children[1].children[0].children[1].textContent
      assert.equal "10",  node.children[1].children[1].children[0].textContent
      assert.equal "125", node.children[1].children[1].children[1].textContent

    test 'should not give child contexts access to the array indexes', ->
      testView = '''
        <div data-define-array="{key: {foo: function(){ return 5; }}}" context="key">
          <div eval="$context.key = 'abcd'">
            <span bind="key"></span>
          </div>
        </div>
      '''

      node = setupView(testView, context = {})
      assert.equal 'abcd', node.children[0].children[0].textContent

  suite "data-eval attribute", ->
    test "should call the given code", ->
      testView = "<span data-eval='myArray.push(\"stuff\")'></span>"

      setupView(testView, context = {myArray: []})

      assert.deepEqual ["stuff"], context.myArray

    test "should work with data-define", ->
      testView = "<div data-define='{myArray: []}''><span data-eval='myArray.push(\"stuff\")'></span></div>"

      setupView(testView, context = {})

      assert.deepEqual ["stuff"], context.myArray

    test "should not mix in the result of eval", ->
      testView = "<div data-eval='{thing: \"stuff\"}'></div>"

      setupView(testView, context = {})

      assert.isUndefined context.thing

    test "should throw a helpful error if trying to eval improperly", ->
      testView = "<div data-define='{myArray: []}'><span data-eval='myArray.push(\"stuff)'></span></div>"

      assert.throw ->
        setupView(testView, context = {})
      , 'Twine error: Unable to create function on SPAN node with attributes data-eval="myArray.push(\\"stuff)"'

  suite "data-allow-default", ->
    test "should prevent default action for an anchor tag", ->
      testView = "<a data-bind-event-click=\"fn()\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.calledOnce

    test "should allow default action for an anchor tag when set to 1", ->
      testView = "<a data-bind-event-click=\"fn()\" data-allow-default=\"1\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should prevent default action for a submit event", ->
      testView = "<form action=\"#\" data-bind-event-submit=\"fn()\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.calledOnce

    test "should allow default action for a submit event when set to 1", ->
      testView = "<form action=\"#\" data-bind-event-submit=\"fn()\" data-allow-default=\"1\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should do nothing unless an anchor tag or submit event", ->
      testView = "<button data-bind-event-click=\"fn()\" data-allow-default=\"0\"></button>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

  suite "data-refresh", ->
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
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, fn: ->)
      @spy(Twine, "refreshImmediately")

      $(node).click()
      @clock.tick 100
      assert.isTrue Twine.refreshImmediately.calledOnce

    test "should happen when a bound input element changes", ->
      testView = "<input data-bind=\"key\">"
      node = setupView(testView, {})
      @spy Twine, "refreshImmediately"

      node.value = "new"
      triggerEvent node, "change"
      @clock.tick 100
      assert.isTrue Twine.refreshImmediately.calledOnce

    test "should not happen if the value did not change", ->
      testView = "<input data-bind=\"key\">"
      node = setupView(testView, {})
      @spy Twine, "refreshImmediately"

      triggerEvent node, "change"
      @clock.tick 100
      assert.isFalse Twine.refreshImmediately.called

  suite "data-bind", ->
    test "should descend contexts", ->
      inner = key: "value"
      testView = "<div data-context=\"inner\"><div data-bind=\"key\"></div></div>"
      node = setupView(testView, inner: inner).children[0]

      assert.equal node.innerHTML, "value"
      assert.equal Twine.context(node), inner

    test "should create the context if it doesn't exist", ->
      testView = "<div data-context=\"inner\"><div data-bind=\"key\">value</div></div>"
      setupView(testView, context = {})
      assert.equal context.inner.key, "value"

    test "should force the node parameter to have its context stored", ->
      testView = "<div></div>"
      node = setupView(testView, context = {})

      Twine.bind(node)
      assert.equal Twine.context(node), context

    test "should fire custom bindings:change", ->
      testView = '<input type="text" data-bind="name">'
      node = setupView(testView, context = {name: "foo"})

      node.addEventListener('bindings:change', eventSpy = @spy())

      context.name = "bar"
      Twine.refreshImmediately()
      assert.ok eventSpy.called

    test "should not bind on hidden fields", ->
      testView = '<input type="hidden" data-bind="name">'
      node = setupView(testView, context = {name: "foo"})

      node.value = "new"
      triggerEvent node, "change"
      assert.equal context.name, "foo"

    test "should not bind on previously binded nodes", ->
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.bind()

      $(node).click()
      assert.isTrue context.fn.calledOnce

  suite "Twine.afterBound", ->
    test "callbacks are passed the context they were defined within", ->
      class window.CallbackTestThing
        called: 0
        constructor: ->
          Twine.afterBound =>
            @called++

      testView = '''
      <div id="outerContext" data-context="outer" data-define="{outer: new CallbackTestThing}">
        <div id="innerContext" data-context="inner" data-define="{inner: new CallbackTestThing}"></div>
      </div>
      '''

      node = setupView(testView, context = {})

      assert.equal 1, Twine.context(node).outer.called
      assert.equal 1, Twine.context(node).outer.inner.called

    test "callbacks can be defined on the rootContext", ->
      called = false
      Twine.afterBound(-> called = true)

      setupView("<div></div>", context = {})
      assert.isTrue called

    test "rebind calls callbacks again", ->
      class window.CallbackTestThing
        @called: 0
        called: 0
        constructor: ->
          Twine.afterBound =>
            @called++
            @constructor.called++

      testView = '<div data-context="inner" data-define="{inner: new CallbackTestThing}"></div>'
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

      Twine.afterBound(-> called = true)
      assert.isTrue called

  suite "reset", ->
    test "should set up the root node", ->
      Twine.reset(context = {}, rootNode)

      assert.equal rootNode.bindingId, 1
      assert.equal Twine.context(rootNode), context

    test "should teardown all elements in memory", ->
      testView = "<div data-bind-event-click=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())
      Twine.bind(node)
      Twine.reset({}, rootNode)

      $(node).click()
      assert.equal context.fn.callCount, 0

  suite "register", ->
    test "should register and resolve from registry", ->
      class TestClass # _not_ global
      Twine.register('TestClass', TestClass)
      testView = "<div data-define='{testClass: new TestClass()}'></div>"
      node = setupView(testView, context = {})

      assert.ok context.testClass
      assert.equal Twine.context(node), context

    test "should throw an error when constructor is local and cannot be resolved", ->
      class NotRegisteredClass # _not_ global
      testView = "<div data-define='{notRegisteredClass: new NotRegisteredClass()}'></div>"

      assert.throw -> setupView(testView, context = {})

    test "should throw an error when name is taken in registry", ->
      Twine.register('component', {})

      assert.throw ->
        Twine.register('component', {})
      , "Twine error: 'component' is already registered with Twine"

    test "should not evaluate from registry outside of 'define' or 'eval'", ->
      Twine.register('outsideOfContext', {message: 'hello world'})
      testView = "<input type='text' data-bind='outsideOfContext.message'></div>"
      setupView(testView, context = {})

      assert.equal context.outsideOfContext.message, ''

  test "context should return the node's context", ->
    testView = '<div data-context="inner"><div data-context="inner"></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.context(node), context
    assert.equal Twine.context(node.firstChild), context.inner

  test "context should return null if the node has no context", ->
    testView = '<div data-context="inner"><div data-context="inner"></div></div>'
    rootNode.innerHTML = testView
    node = rootNode.children[0]

    assert.equal null, Twine.context(node)

  test "childContext should return the node's childrens' context", ->
    testView = '<div data-context="inner"><div data-context="inner"></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.childContext(node), context.inner
    assert.equal Twine.childContext(node.firstChild), context.inner.inner

  test "contextKey should return the key", ->
    testView = '<div data-context="inner"><div data-context="inner"><div></div></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.contextKey(node), ''
    assert.equal Twine.contextKey(node.firstChild), 'inner'
    assert.equal Twine.contextKey(node.firstChild.firstChild), 'inner.inner'

  test "contextKey should accept an extra context to use as the last key element", ->
    testView = '<div data-context="inner"><div data-context="inner"><div></div></div></div>'
    node = setupView(testView, context = {inner: {inner: {}}})

    assert.equal Twine.contextKey(node.firstChild, context.inner.inner), 'inner.inner'

suite "TwineLegacy", ->
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
      testView = "<div bind-attribute=\"{a: key, b: false, c: 0, d: null, e: undefined, f: function() { return true }, g: '0', h: 'false'}\"></div>"
      node = setupView(testView, key: true)
      assert.equal node.getAttribute('a'), 'true'
      assert.isFalse node.hasAttribute('b')
      assert.isFalse node.hasAttribute('c')
      assert.isFalse node.hasAttribute('d')
      assert.isFalse node.hasAttribute('e')
      assert.equal node.getAttribute('f'), 'true'
      assert.equal node.getAttribute('g'), '0'
      assert.equal node.getAttribute('h'), 'false'

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

  suite "bind-event-paste attribute", ->
    test "should run the handler on paste", ->
      testView = "<div bind-event-paste=\"fn()\"></div>"
      node = setupView(testView, context = fn: @spy())

      $(node).trigger 'paste'
      assert.isTrue context.fn.calledOnce

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
      , 'Twine error: Unable to create function on DIV node with attributes define="{key: \'value\', key2: \'value2"'

  suite "eval attribute", ->
    test "should call the given code", ->
      testView = "<span eval='myArray.push(\"stuff\")'></span>"

      setupView(testView, context = {myArray: []})

      assert.deepEqual ["stuff"], context.myArray

    test "should work with define", ->
      testView = "<div define='{myArray: []}''><span eval='myArray.push(\"stuff\")'></span></div>"

      setupView(testView, context = {})

      assert.deepEqual ["stuff"], context.myArray

    test "should not mix in the result of eval", ->
      testView = "<div eval='{thing: \"stuff\"}'></div>"

      setupView(testView, context = {})

      assert.isUndefined context.thing

    test "should throw a helpful error if trying to eval improperly", ->
      testView = "<div define='{myArray: []}'><span eval='myArray.push(\"stuff)'></span></div>"

      assert.throw ->
        setupView(testView, context = {})
      , 'Twine error: Unable to create function on SPAN node with attributes eval="myArray.push(\\"stuff)"'

  suite "allow-default", ->
    test "should prevent default action for an anchor tag", ->
      testView = "<a bind-event-click=\"fn()\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.calledOnce

    test "should allow default action for an anchor tag when set to true", ->
      testView = "<a bind-event-click=\"fn()\" allow-default=\"true\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should allow default action for an anchor tag when set to anything but false", ->
      testView = "<a bind-event-click=\"fn()\" allow-default=\"1\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should prevent default action for anchor tag when set to false", ->
      testView = "<a bind-event-click=\"fn()\" allow-default=\"false\"></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.called

    test "should allow default action when allow-default is present", ->
      testView = "<a bind-event-click=\"fn()\" allow-default></a>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should prevent default action for a submit event", ->
      testView = "<form action=\"#\" bind-event-submit=\"fn()\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.calledOnce

    test "should allow default action for a submit event when set to true", ->
      testView = "<form action=\"#\" bind-event-submit=\"fn()\" allow-default=\"true\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should allow default action for a submit event when set to anything but false", ->
      testView = "<form action=\"#\" bind-event-submit=\"fn()\" allow-default=\"1\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

    test "should prevent default action for a submit event when set to false", ->
      testView = "<form action=\"#\" bind-event-submit=\"fn()\" allow-default=\"false\"></form>"
      event = {type: 'submit', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isTrue event.preventDefault.calledOnce

    test "should do nothing unless an anchor tag or submit event", ->
      testView = "<button bind-event-click=\"fn()\" allow-default=\"0\"></button>"
      event = {type: 'click', preventDefault: @spy()}
      node = setupView(testView, fn: ->)

      $(node).trigger(event)
      assert.isFalse event.preventDefault.called

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

  suite "Twine.afterBound", ->
    test "callbacks are passed the context they were defined within", ->
      class window.CallbackTestThing
        called: 0
        constructor: ->
          Twine.afterBound =>
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
      Twine.afterBound(-> called = true)

      setupView("<div></div>", context = {})
      assert.isTrue called

    test "rebind calls callbacks again", ->
      class window.CallbackTestThing
        @called: 0
        called: 0
        constructor: ->
          Twine.afterBound =>
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

      Twine.afterBound(-> called = true)
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

  test "context should return null if the node has no context", ->
    testView = '<div context="inner"><div context="inner"></div></div>'
    rootNode.innerHTML = testView
    node = rootNode.children[0]

    assert.equal null, Twine.context(node)

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

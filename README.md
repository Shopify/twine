twine
-----

Twine is a minimalistic set of 2-way bindings.  It allows you to define JS execution contexts using strings of JS defined directly on top of the DOM.

Usage
=====

`bind`:

e.g., `<input type="text" bind="firstName">`

Binds a variable within a context to the `textContent` or `value` of the DOM node in question.

If the variable is currently falsy and `bind` is used on a user-input node, then the variable will be initialized to the current value of that node.

e.g., `<input type="text" bind="firstName" value="Jack">` arrives from the server.  When bindings are refreshed, the initial value of `firstName`, if not previously defined, will become `Jack`.

If `firstName` already had the value `Jon`, then the input's value would change to `Jon`.

Bind can also be used to change the text content of any node.

e.g., `<span bind="firstName"></span>` coupled with the above `input` would cause this `span`'s content to reflect whatever was typed.

Events
======

DOM events are available for quick bindings.

e.g., `<button bind-event-click="window.foo()">Click me!</button>` would call the `window.foo()` function when clicked.

By default, the default behaviour (think `preventDefault`) will be prevented, unless either:

- `event.type == submit`
- the node the event was bound on was an `<a>`

Additionally, the presence of `allow-default` attribute will cause the twine system to never prevent default, rending these two exceptions above moot.

The following events are provided:

- `click`
- `dblclick`
- `mousedown`
- `mouseup`
- `submit`
- `dragenter`
- `dragleave`
- `dragover`
- `drop`
- `drag`
- `change`
- `keypress`
- `keydown`
- `keyup`
- `input`
- `error`
- `done`
- `fail`
- `blur`
- `focus`

reflecting common DOM events.

When defining events on nodes, you have access to:

- `$context`
- `$root`
- `event`
- `data`

If you wanted to access the typical click data of an event object, you could do:

```html
<button bind-event-click="foo(event)">Click me!</button>
```

In this case, your `foo` function is passed the `event` details.

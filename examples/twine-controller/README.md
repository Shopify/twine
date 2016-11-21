# Example
If you just want to see an example of this stuff go here
http://codepen.io/themallen/pen/zoozZX?editors=1010

# Controller Binding
The binding type itself is quite simple, and really only has 4 responsibilities.
- instantiating an instance of the constructor in the `registry` matching the `data-controller` attribute
- setting the `context` for any child bindings to that of the new instance
- passing data down into the instance based on the `data-prop-*` and `data-pass-prop-*` attributes
- invoking lifecycle events when appropriate

## Controller Binding Lifecycle
Twine controller bindings call the following lifecycle methods on their instance.

### Constructor
Called during initial bind, the constructor is passed the bound `node`, parsed `props` and it's parent twine `context`.

### Refresh
Called every time bindings are refreshed, the refresh method is passed `oldProps` and `newProps`

### Teardown
Called when bindings are removed

## Props
There are two attribute types which twine cares about for the purposes of passing props into a controller constructor.

### data-prop:
Basic literal prop binding. Props defined this way are parsed as a json and passed into the corresponding key on the `props` object.

```
class Widget {
  constructor(node, props, context) {
    this.type = props.widget.type;
    this.knob = props.knob;
  }
}
Twine.register('Widget', Widget);
...

<div data-controller="Widget" data-prop-widget-type="bleeper">
  <p data-bind="type"></p>
</div>

<div data-controller="Widget" data-prop-widget-type="meeper" data-prop-knob="{
    "puppiness": 4
  }">
  <p data-bind="type"></p>
  <span data-bind="knob.puppiness"></span>
</div>
```

### data-pass-prop
Keypath prop binding. Props defined this way trigger twine to look for the attribute value in the current context as a keypath. Allows you to pass data down the controller tree.

```
class Widgets {
  constructor(node, props, context) {
    this.widgets = [{"type": "bleeper"}, {"type": "meeper"}];
  }
}

class Wobbler {
  constructor(node, props, context) {
    this.wobblables = props.wobblables;
  }

  wobble() {
    this.wobblables.forEach((wobblable) => {
      // wobble logic here
    }
  }
}
Twine
  .register('Widgets', Widgets)
  .register('Wobbler', Wobbler)
...

<div data-controller="Widgets">
  <div data-controller="Wobbler" data-pass-prop-wobblables="widgets"></div>
</div>
```

# TwineController Base Class
The `TwineController` base class adds some tools and additional lifecycle events to the controller binding type and helps avoid boilerplate.

## Additional Lifecycle events
### init
`init` is called by the `TwineController` constructor, and is preferred to defining an inherited controllers constructor. `init` is not passed any arguments, however when it runs the constructor has already assigned `node`, `props` and `context` to properties on `this`.
### afterBound
`afterBound` is called after the `node` (and it's children) have finished binding.
### afterRefresh
`afterRefresh` is called when `Twine` has finished a refresh

## Additional props helpers
`data-prop-*-as` lets you automatically assign props onto properties on the controller.

## Example
```
class Widgets extends TwineController{
}

class Wobbler extends TwineController{
  wobble() {
    this.wobblables.forEach((wobblable) => {
      // wobble logic here
    }
  }
}

Twine
  .register('Widgets', Widgets)
  .register('Wobbler', Wobbler)
...

<div data-controller="Widgets"
  data-prop-widgets="[{"type": "bleeper"}, {"type": "meeper"}]"
  data-prop-widgets-as="widgets">
  <div data-controller="Wobbler"
    data-pass-prop-wobblables="widgets"
    data-prop-wobblables-as="wobblables">
  </div>
</div>
```

# Twine Iterator Class
Iterator builds ontop of TwineController to allow simple template iteration without putting node removal / addition logic inside of `Twine` itself.

## Template tags
`Iterator` uses a tiny micro templating solution which only knows how to substitute keypath values into `{{handleBar}}` type tokens.

## Attributes of note
- `data-pass-prop-collection`, put this on an iterator to pass in a collection to iterate over
- `data-prop-collection-as`, can be useful to give simplified access to a context value to child nodes of the iterator
- `data-iterator-template`, put this on a template tag to have it parsed and used for each iteration
- `data-iterator-empty-template`, put this on a template tag to have it used for when the collection is empty


```
class Widgets extends TwineController{
}

class WobbleClickWidget extends TwineController{
  wobble() {
    // wobble logic here
  }
}

Twine
  .register('Widgets', Widgets)
  .register('WobbleClickWidget', WobbleClickWidget)
...

<div data-controller="Widgets"
  data-prop-widgets="[{"type": "bleeper"}, {"type": "meeper"}]">
  <div data-controller="Iterator"
    data-pass-prop-collection="widgets"
    data-prop-collection-as="widgets">
    <script type="text/template" data-iterator-empty-template>
      No widgets here :(
    </script>
    <script type="text/template" data-iterator-template>
      <span data-controller="WobbleClickWidget" data-prop-widget="widgets[{{$index}}]">
        <button data-bind-event-click="wobble">Wobble</button>
      </span>
    </script>
  </div>
</div>
```

(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var attribute, bind, currentBindingCallbacks, elements, eventName, fireCustomChangeEvent, getContext, getValue, isKeypath, keypathForKey, keypathRegex, nodeCount, preventDefaultForEvent, refreshElement, refreshQueued, rootContext, rootNode, setValue, setupAttributeBinding, setupEventBinding, stringifyNodeAttributes, valueAttributeForNode, wrapFunctionString, _i, _j, _len, _len1, _ref, _ref1,
  __slice = [].slice;

window.Twine = {};

Twine.shouldDiscardEvent = {};

elements = {};

nodeCount = 0;

rootContext = null;

keypathRegex = /^[a-z]\w*(\.[a-z]\w*|\[\d+\])*$/i;

refreshQueued = false;

rootNode = null;

currentBindingCallbacks = null;

Twine.reset = function(newContext, node) {
  var bindings, key, obj, _i, _len, _ref;
  if (node == null) {
    node = document.documentElement;
  }
  for (key in elements) {
    if (bindings = (_ref = elements[key]) != null ? _ref.bindings : void 0) {
      for (_i = 0, _len = bindings.length; _i < _len; _i++) {
        obj = bindings[_i];
        if (obj.teardown) {
          obj.teardown();
        }
      }
    }
  }
  elements = {};
  rootContext = newContext;
  rootNode = node;
  rootNode.bindingId = nodeCount = 1;
  return this;
};

Twine.bind = function(node, context) {
  if (node == null) {
    node = rootNode;
  }
  if (context == null) {
    context = Twine.context(node);
  }
  return bind(context, node, true);
};

Twine.afterBound = function(callback) {
  if (currentBindingCallbacks) {
    return currentBindingCallbacks.push(callback);
  } else {
    return callback();
  }
};

bind = function(context, node, forceSaveContext) {
  var binding, callback, callbacks, childNode, definition, element, fn, keypath, newContextKey, type, _i, _j, _len, _len1, _ref, _ref1, _ref2;
  currentBindingCallbacks = [];
  if (node.bindingId) {
    Twine.unbind(node);
  }
  _ref = Twine.bindingTypes;
  for (type in _ref) {
    binding = _ref[type];
    if (!(definition = node.getAttribute(type) || node.getAttribute("data-" + type))) {
      continue;
    }
    if (!element) {
      element = {
        bindings: []
      };
    }
    fn = binding(node, context, definition, element);
    if (fn) {
      element.bindings.push(fn);
    }
  }
  if (newContextKey = node.getAttribute('context')) {
    keypath = keypathForKey(newContextKey);
    if (keypath[0] === '$root') {
      context = rootContext;
      keypath = keypath.slice(1);
    }
    context = getValue(context, keypath) || setValue(context, keypath, {});
  }
  if (element || newContextKey || forceSaveContext) {
    (element != null ? element : element = {}).childContext = context;
    elements[node.bindingId != null ? node.bindingId : node.bindingId = ++nodeCount] = element;
  }
  callbacks = currentBindingCallbacks;
  _ref1 = node.children || [];
  for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
    childNode = _ref1[_i];
    bind(context, childNode);
  }
  Twine.count = nodeCount;
  _ref2 = callbacks || [];
  for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
    callback = _ref2[_j];
    callback();
  }
  currentBindingCallbacks = null;
  return Twine;
};

Twine.refresh = function() {
  if (refreshQueued) {
    return;
  }
  refreshQueued = true;
  return setTimeout(Twine.refreshImmediately, 0);
};

refreshElement = function(element) {
  var obj, _i, _len, _ref;
  if (element.bindings) {
    _ref = element.bindings;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      obj = _ref[_i];
      if (obj.refresh != null) {
        obj.refresh();
      }
    }
  }
};

Twine.refreshImmediately = function() {
  var element, key;
  refreshQueued = false;
  for (key in elements) {
    element = elements[key];
    refreshElement(element);
  }
};

Twine.change = function(node, bubble) {
  var event;
  if (bubble == null) {
    bubble = false;
  }
  event = document.createEvent("HTMLEvents");
  event.initEvent('change', bubble, true);
  return node.dispatchEvent(event);
};

Twine.unbind = function(node) {
  var bindings, childNode, id, obj, _i, _j, _len, _len1, _ref, _ref1;
  if (id = node.bindingId) {
    if (bindings = (_ref = elements[id]) != null ? _ref.bindings : void 0) {
      for (_i = 0, _len = bindings.length; _i < _len; _i++) {
        obj = bindings[_i];
        if (obj.teardown) {
          obj.teardown();
        }
      }
    }
    delete elements[id];
    delete node.bindingId;
  }
  _ref1 = node.children || [];
  for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
    childNode = _ref1[_j];
    Twine.unbind(childNode);
  }
  return this;
};

Twine.context = function(node) {
  return getContext(node, false);
};

Twine.childContext = function(node) {
  return getContext(node, true);
};

getContext = function(node, child) {
  var context, id, _ref;
  while (node) {
    if (node === rootNode) {
      return rootContext;
    }
    if (!child) {
      node = node.parentNode;
    }
    if (!node) {
      console.warn("Unable to find context; please check that the node is attached to the DOM that Twine has bound, or that bindings have been initiated on this node's DOM");
      return null;
    }
    if ((id = node.bindingId) && (context = (_ref = elements[id]) != null ? _ref.childContext : void 0)) {
      return context;
    }
    if (child) {
      node = node.parentNode;
    }
  }
};

Twine.contextKey = function(node, lastContext) {
  var addKey, context, id, keys, _ref;
  keys = [];
  addKey = function(context) {
    var key, val;
    for (key in context) {
      val = context[key];
      if (!(lastContext === val)) {
        continue;
      }
      keys.unshift(key);
      break;
    }
    return lastContext = context;
  };
  while (node && node !== rootNode && (node = node.parentNode)) {
    if ((id = node.bindingId) && (context = (_ref = elements[id]) != null ? _ref.childContext : void 0)) {
      addKey(context);
    }
  }
  if (node === rootNode) {
    addKey(rootContext);
  }
  return keys.join('.');
};

valueAttributeForNode = function(node) {
  var name, _ref;
  name = node.nodeName.toLowerCase();
  if (name === 'input' || name === 'textarea' || name === 'select') {
    if ((_ref = node.getAttribute('type')) === 'checkbox' || _ref === 'radio') {
      return 'checked';
    } else {
      return 'value';
    }
  } else {
    return 'textContent';
  }
};

keypathForKey = function(key) {
  var end, keypath, start, _i, _len, _ref;
  keypath = [];
  _ref = key.split('.');
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    key = _ref[_i];
    if ((start = key.indexOf('[')) !== -1) {
      keypath.push(key.substr(0, start));
      key = key.substr(start);
      while ((end = key.indexOf(']')) !== -1) {
        keypath.push(parseInt(key.substr(1, end), 10));
        key = key.substr(end + 1);
      }
    } else {
      keypath.push(key);
    }
  }
  return keypath;
};

getValue = function(object, keypath) {
  var key, _i, _len;
  for (_i = 0, _len = keypath.length; _i < _len; _i++) {
    key = keypath[_i];
    if (object != null) {
      object = object[key];
    }
  }
  return object;
};

setValue = function(object, keypath, value) {
  var key, lastKey, _i, _j, _len, _ref;
  _ref = keypath, keypath = 2 <= _ref.length ? __slice.call(_ref, 0, _i = _ref.length - 1) : (_i = 0, []), lastKey = _ref[_i++];
  for (_j = 0, _len = keypath.length; _j < _len; _j++) {
    key = keypath[_j];
    object = object[key] != null ? object[key] : object[key] = {};
  }
  return object[lastKey] = value;
};

stringifyNodeAttributes = function(node) {
  var attr, i, nAttributes, result;
  nAttributes = node.attributes.length;
  i = 0;
  result = "";
  while (i < nAttributes) {
    attr = node.attributes.item(i);
    result += "" + attr.nodeName + "='" + attr.textContent + "'";
    i += 1;
  }
  return result;
};

wrapFunctionString = function(code, args, node) {
  var e, keypath;
  if (isKeypath(code) && (keypath = keypathForKey(code))) {
    if (keypath[0] === '$root') {
      return function($context, $root) {
        return getValue($root, keypath);
      };
    } else {
      return function($context, $root) {
        return getValue($context, keypath);
      };
    }
  } else {
    try {
      return new Function(args, "with($context) { return " + code + " }");
    } catch (_error) {
      e = _error;
      throw "Twine error: Unable to create function on " + node.nodeName + " node with attributes " + (stringifyNodeAttributes(node));
    }
  }
};

isKeypath = function(value) {
  return (value !== 'true' && value !== 'false' && value !== 'null' && value !== 'undefined') && keypathRegex.test(value);
};

fireCustomChangeEvent = function(node) {
  var event;
  event = document.createEvent('CustomEvent');
  event.initCustomEvent('bindings:change', true, false, {});
  return node.dispatchEvent(event);
};

Twine.bindingTypes = {
  bind: function(node, context, definition) {
    var changeHandler, checkedValueType, eventType, fn, j, keypath, lastValue, len, oldValue, ref, refresh, refreshContext, teardown, twoWayBinding, value, valueAttribute;
    valueAttribute = valueAttributeForNode(node);
    value = node[valueAttribute];
    lastValue = void 0;
    teardown = void 0;
    checkedValueType = node.getAttribute('type') === 'radio';
    fn = wrapFunctionString(definition, '$context,$root', node);
    refresh = function() {
      var newValue;
      newValue = fn.call(node, context, rootContext);
      if (newValue === lastValue) {
        return;
      }
      lastValue = newValue;
      if (newValue === node[valueAttribute]) {
        return;
      }
      node[valueAttribute] = checkedValueType ? newValue === node.value : newValue;
      return fireCustomChangeEvent(node);
    };
    if (!isKeypath(definition)) {
      return {
        refresh: refresh
      };
    }
    refreshContext = function() {
      if (checkedValueType) {
        if (!node.checked) {
          return;
        }
        return setValue(context, keypath, node.value);
      } else {
        return setValue(context, keypath, node[valueAttribute]);
      }
    };
    keypath = keypathForKey(definition);
    twoWayBinding = valueAttribute !== 'textContent' && node.type !== 'hidden';
    if (keypath[0] === '$root') {
      context = rootContext;
      keypath = keypath.slice(1);
    }
    if ((value != null) && (twoWayBinding || value !== '') && ((oldValue = getValue(context, keypath)) == null)) {
      refreshContext();
    }
    if (twoWayBinding) {
      changeHandler = function() {
        if (getValue(context, keypath) === this[valueAttribute]) {
          return;
        }
        refreshContext();
        return Twine.refreshImmediately();
      };
      ref = ['input', 'keyup', 'change'];
      for (j = 0, len = ref.length; j < len; j++) {
        eventType = ref[j];
        node.addEventListener(eventType, changeHandler, false);
      }
      teardown = function() {
        var k, len1, ref1, results;
        ref1 = ['input', 'keyup', 'change'];
        results = [];
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          eventType = ref1[k];
          results.push(node.removeEventListener(eventType, changeHandler, false));
        }
        return results;
      };
    }
    return {
      refresh: refresh,
      teardown: teardown
    };
  },
  'bind-show': function(node, context, definition) {
    var fn, lastValue;
    fn = wrapFunctionString(definition, '$context,$root', node);
    lastValue = void 0;
    return {
      refresh: function() {
        var newValue;
        newValue = !fn.call(node, context, rootContext);
        if (newValue === lastValue) {
          return;
        }
        if (lastValue = newValue) {
          return node.classList.add('hide');
        } else {
          return node.classList.remove('hide');
        }
      }
    };
  },
  'bind-class': function(node, context, definition) {
    var fn, lastValue;
    fn = wrapFunctionString(definition, '$context,$root', node);
    lastValue = {};
    return {
      refresh: function() {
        var key, newValue, value;
        newValue = fn.call(node, context, rootContext);
        for (key in newValue) {
          value = newValue[key];
          if (!lastValue[key] !== !value) {
            if (!!value) {
              node.classList.add(key);
            } else {
              node.classList.remove(key);
            }
          }
        }
        return lastValue = newValue;
      }
    };
  },
  'bind-attribute': function(node, context, definition) {
    var fn, lastValue;
    fn = wrapFunctionString(definition, '$context,$root', node);
    lastValue = {};
    return {
      refresh: function() {
        var key, newValue, value;
        newValue = fn.call(node, context, rootContext);
        for (key in newValue) {
          value = newValue[key];
          if (lastValue[key] !== value) {
            if (value) {
              if (typeof value === 'function') {
                value = value.call();
              }
              node.setAttribute(key, value);
            } else {
              node.removeAttribute(key);
            }
          }
        }
        return lastValue = newValue;
      }
    };
  },
  define: function(node, context, definition) {
    var fn, key, object, value;
    fn = wrapFunctionString(definition, '$context,$root', node);
    object = fn.call(node, context, rootContext);
    for (key in object) {
      value = object[key];
      context[key] = value;
    }
  },
  "eval": function(node, context, definition) {
    var fn;
    fn = wrapFunctionString(definition, '$context,$root', node);
    fn.call(node, context, rootContext);
  }
};

setupAttributeBinding = function(attributeName, bindingName) {
  var booleanAttribute;
  booleanAttribute = attributeName === 'checked' || attributeName === 'disabled' || attributeName === 'readOnly';
  return Twine.bindingTypes["bind-" + bindingName] = function(node, context, definition) {
    var fn, lastValue;
    fn = wrapFunctionString(definition, '$context,$root', node);
    lastValue = void 0;
    return {
      refresh: function() {
        var newValue;
        newValue = fn.call(node, context, rootContext);
        if (booleanAttribute) {
          newValue = !!newValue;
        }
        if (newValue === lastValue) {
          return;
        }
        node[attributeName] = lastValue = newValue;
        if (attributeName === 'checked') {
          return fireCustomChangeEvent(node);
        }
      }
    };
  };
};

_ref = ['placeholder', 'checked', 'disabled', 'href', 'title', 'readOnly', 'src'];
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  attribute = _ref[_i];
  setupAttributeBinding(attribute, attribute);
}

setupAttributeBinding('innerHTML', 'unsafe-html');

preventDefaultForEvent = function(event) {
  return (event.type === 'submit' || event.currentTarget.nodeName.toLowerCase() === 'a') && event.currentTarget.getAttribute('allow-default') !== '1';
};

setupEventBinding = function(eventName) {
  return Twine.bindingTypes["bind-event-" + eventName] = function(node, context, definition) {
    var onEventHandler;
    onEventHandler = function(event, data) {
      var discardEvent, _base;
      if (data == null) {
        data = event.detail;
      }
      discardEvent = typeof (_base = Twine.shouldDiscardEvent)[eventName] === "function" ? _base[eventName](event) : void 0;
      if (discardEvent || preventDefaultForEvent(event)) {
        event.preventDefault();
      }
      if (discardEvent) {
        return;
      }
      wrapFunctionString(definition, '$context,$root,event,data', node).call(node, context, rootContext, event, data);
      return Twine.refreshImmediately();
    };
    node.addEventListener(eventName, onEventHandler, false);
    return {
      teardown: function() {
        return node.removeEventListener(eventName, onEventHandler, false);
      }
    };
  };
};

_ref1 = ['click', 'dblclick', 'mouseenter', 'mouseleave', 'mouseover', 'mouseout', 'mousedown', 'mouseup', 'submit', 'dragenter', 'dragleave', 'dragover', 'drop', 'drag', 'change', 'keypress', 'keydown', 'keyup', 'input', 'error', 'done', 'success', 'fail', 'blur', 'focus', 'load'];
for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
  eventName = _ref1[_j];
  setupEventBinding(eventName);
}



},{}]},{},[1]);

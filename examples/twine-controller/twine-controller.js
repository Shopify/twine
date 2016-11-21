import Twine from 'twine';

export default class TwineController {
  constructor(node, props, _context) {
    this._bindFunctions([
      'init',
      'afterBound',
      'refresh',
      'afterRefresh',
      'teardown',
      '_teardown',
      'renderToDOM',
      'destroy'
    ])
    this.node = node;
    this.props = props;
    this.setupPropAliases();
    this._context = _context;
    this.init();
    Twine.afterBound(this.afterBound.bind(this));

    document.addEventListener('Twine:refresh:complete', this.afterRefresh);
  }

  init() {}
  afterBound() {}
  refresh() {}
  afterRefresh() {}
  teardown() {}

  renderToDOM() {
    let output = this.render();
    if (output != this.node.innerHTML) {
      Array.from(this.node.children).forEach((child) => {
        Twine.unbind(child, this._contextForChildren())
      })
      this.node.innerHTML = output;
      Array.from(this.node.children).forEach((child) => {
        Twine.bind(child, this._contextForChildren());
      })
    }

  }

  forceRefresh(immediate=false) {
    if (immediate) {
      return Twine.refreshImmediately();
    }
    Twine.refresh();
  }

  setupPropAliases() {
    Object.keys(this.props).forEach((key) => {
      const keyAs = this.props[`${key}As`];
      if (keyAs) {
        this[keyAs] = this.props[key];
      }
    });
  }

  destroy() {
    Twine.unbind(this.node);
    return this.node.remove();
  }

  _contextForChildren() {
    return this;
  }

  _bindFunctions(functionNames) {
    if (!Array.isArray(functionNames)) {
      functionNames = [functionNames];
    }
    functionNames.forEach(
      (name) => this[name] = this[name].bind(this)
    );
  }

  _teardown() {
    document.removeEventListener('Twine:refresh:complete', this.afterRefresh);
    this.teardown();
  }
};

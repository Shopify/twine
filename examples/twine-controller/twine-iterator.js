import TwineController from './twine-controller';
import Twine from 'twine';

export default class TwineIterator extends TwineController {
  init() {
    const templateNode = this.node.querySelector('script[data-iterator-template]');
    const emptyTemplateNode = this.node.querySelector('script[data-iterator-empty-template]');

    this.templates = {
      item: templateNode.innerHTML,
      empty: emptyTemplateNode ? emptyTemplateNode.innerHTML : ''
    };

    if (this.props.renderImmediately) {
      this.renderToDOM;
    }
  }

  refresh(oldProps, newProps) {
    if (newProps) {
      this.props = newProps;
    }
    this.renderToDOM();
  }

  contextForChildren() {
    return this._context;
  }

  render() {
    if (this.props.collection.length === 0) {
      return this.templates.empty;
    }
    return this.props.collection
      .map((thing, index) => templateEngine(this.templates.item, thing, index))
      .join('')
  }
}

function getValueForKeypath(object, keypath) {
    if (keypath.indexOf('.') === -1) {
      return getValueForKey(object, keypath);
    }

    const segments = keypath.split('.');
    const firstKey = segments.shift();
    const remainingKeypath = segments.join('.');

    return getValueForKeypath(object[firstKey], remainingKeypath);
}

function getValueForKey(object, key) {
  if (typeof object === 'object') {
    return object[key];
  }
}

function templateEngine(template, data, index) {
  const templateRegex = /{{([^}}]+)?}}/g;
  return template.replace(templateRegex, (match, content) => {
    if (content.valueOf() == '$index') {
      return index;
    }
    return getValueForKeypath(data, content) || '';
  });
}

Twine.register('iterator', TwineIterator);

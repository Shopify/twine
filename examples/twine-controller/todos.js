import TwineController from 'admin/tnt/twine-controller';
import Dispatcher from 'admin/lib/dispatcher';
const dispatcher = new Dispatcher();

const todos = [];
export class Todos extends TwineController {
  init() {
    this.todos = todos;
    this._bindFunctions(['addTodo', 'markDone']);
    dispatcher.register('todos:add', this.addTodo);
    dispatcher.register('todos:done', this.markDone);
  }

  refresh() {
    this.updateTodos();
  }

  updateTodos() {
    this.doneTodos = this.todos.filter((todo) => todo.done);
    this.pendingTodos = this.todos.filter((todo) => !todo.done);
  }

  markDone({id}) {
    const todo = this.todos.find((todo) => todo.id === id)
    todo.done = true;
    this.forceRefresh();
  }

  addTodo({todo}) {
    todo.id = this.nextid();
    this.todos.push(todo);
    this.forceRefresh(true);
  }

  nextid() {
    currentId += 1;
    return currentId;
  }
}

let currentId = 0;
export class Todo extends TwineController {
  init() {
    this._bindFunctions('done');
  }

  done() {
    dispatcher.dispatch({
      type: 'todos:done',
      id: Number(this.props.id)
    });
  }
}

export class TodoForm extends TwineController {
  init() {
    this._bindFunctions('submit');
  }

  submit() {
    dispatcher.dispatch({
      type: 'todos:add',
      todo: {
        text: this.text,
        done: false
      }
    });
  }
}

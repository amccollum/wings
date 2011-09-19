var assert, assertTypeOf, callback, defaultMessage, defaultMessages, defaults, events, isArray, isObject, isString, key, n, reporters, stylizers, typeOf, vows, _ref, _stack;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
  for (var i = 0, l = this.length; i < l; i++) {
    if (this[i] === item) return i;
  }
  return -1;
};
events = require('events');
vows = typeof provide !== "undefined" && provide !== null ? provide('vows', {}) : typeof exports !== "undefined" && exports !== null ? exports : (this.vows = {});
vows.add = function(description, tests, options) {
  var suite;
  suite = new vows.Context(description, tests, options);
  vows.runner.add(suite);
  return suite;
};
vows.describe = function(description, options) {
  return vows.add(description, Array.prototype.slice.call(arguments, 1), options);
};
vows.run = function() {
  return vows.runner.run();
};
vows.VowsError = (function() {
  __extends(VowsError, Error);
  function VowsError(context, message) {
    this.context = context;
    this.message = message;
    this.message = "" + this.context.description + ": " + this.message;
  }
  VowsError.prototype.toString = function() {
    return "" + this.context.description + ": " + this.message;
  };
  return VowsError;
})();
vows.Context = (function() {
  __extends(Context, events.EventEmitter);
  function Context(description, content, options, parent) {
    this.callback = __bind(this.callback, this);
    var key, value, _i, _j, _len, _len2, _ref, _ref2;
    this.description = description;
    this.parent = parent;
    this._events = {
      maxListeners: 100
    };
    this.options = options != null ? options : {};
    this.matched = (!(this.options.matcher != null)) || ((_ref = this.parent) != null ? _ref.matched : void 0) || this.options.matcher.test(this.description);
    this.results = {
      startDate: null,
      endDate: null
    };
    _ref2 = ['total', 'running', 'honored', 'pending', 'broken', 'errored'];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      key = _ref2[_i];
      this.results[key] = 0;
    }
    switch (typeof content) {
      case 'string':
        this.type = 'comment';
        this.results.total = 1;
        this.content = content;
        break;
      case 'function':
        this.type = 'test';
        this.results.total = 1;
        this.content = content;
        break;
      case 'object':
        if (content.length != null) {
          this.type = 'batch';
          this.content = [];
          for (_j = 0, _len2 = content.length; _j < _len2; _j++) {
            value = content[_j];
            this.add(new vows.Context(null, value, this.options, this));
          }
        } else {
          this.type = 'group';
          this.content = {};
          for (key in content) {
            value = content[key];
            if (key === 'topic' || key === 'async' || key === 'setup' || key === 'teardown') {
              if (key === 'topic') {
                this.hasTopic = true;
              }
              this[key] = value;
            } else {
              this.add(new vows.Context(key, value, this.options, this));
            }
          }
        }
        break;
      default:
        throw new vows.VowsError(this, 'Unknown content type');
    }
  }
  Context.prototype.report = function() {
    if (!this.options.silent) {
      return vows.report.apply(this, arguments);
    }
  };
  Context.prototype._errorPattern = /^function\s*\w*\s*\(\s*(e|err|error)\b/;
  Context.prototype.run = function(topics) {
    var batch, child, cur, key, next, _fn, _ref, _ref2;
    this.topics = topics != null ? Array.prototype.slice.call(topics) : [];
    this.results.startDate = new Date;
    __bind(function() {
      var Env, context;
      context = this;
      return this.env = new (Env = (function() {
        function Env() {
          this.context = context;
          this.topics = context.topics;
          this.success = function() {
            return context.success.apply(context, arguments);
          };
          this.error = function() {
            return context.error.apply(context, arguments);
          };
          this.callback = function() {
            return context.callback.apply(context, arguments);
          };
        }
        Env.prototype = (context.parent ? context.parent.env : {});
        Env.prototype.constructor = Env;
        return Env;
      })());
    }, this)();
    if (this.matched) {
      this.emit(this.status = 'begin');
    } else {
      this.emit(this.status = 'skip');
      return this.end('skipped');
    }
    if (this.parent === vows.runner) {
      if (this.description) {
        this.report('subject', this.description);
      }
    }
    switch (this.type) {
      case 'comment':
        this.end('pending');
        break;
      case 'test':
        try {
          this.content.apply(this.env, this.topics);
          this.end('honored');
        } catch (e) {
          this.exception = e;
          if ((_ref = e.name) != null ? _ref.match(/AssertionError/) : void 0) {
            this.end('broken');
          } else {
            this.end('errored');
          }
        }
        break;
      case 'batch':
        if (!this.content.length) {
          return this.end('done');
        }
        batch = this.content.slice();
        while (batch.length) {
          cur = batch.pop();
          if (typeof next !== "undefined" && next !== null) {
            cur.on('end', (function(next) {
              return function() {
                return next.run(topics);
              };
            })(next));
          } else {
            cur.on('end', __bind(function() {
              return this.end('done');
            }, this));
          }
          next = cur;
        }
        cur.run(this.topics);
        break;
      case 'group':
        if (!((function() {
          var _results;
          _results = [];
          for (key in this.content) {
            _results.push(key);
          }
          return _results;
        }).call(this)).length) {
          return this.end('end');
        }
        if (this.setup != null) {
          try {
            this.setup.apply(this.env, this.topics);
          } catch (e) {
            this.exeption = e;
            return this.end('errored');
          }
        }
        this.on('topic', __bind(function() {
          var args;
          if (this.hasTopic) {
            args = Array.prototype.slice.call(arguments);
            return this.topics = args.concat(this.topics);
          }
        }, this));
        this.hasTests = false;
        _ref2 = this.content;
        _fn = __bind(function(child) {
          this.results.running++;
          if (!this.hasTests && child.type === 'test') {
            this.hasTests = true;
            this.on('run', __bind(function() {
              var context, parts;
              context = this;
              parts = [this.description];
              while ((context = context.parent) && context.parent !== vows.runner) {
                if (context.description) {
                  parts.unshift(context.description);
                }
              }
              return this.report('context', {
                description: parts.join(' ')
              });
            }, this));
          }
          this.on('topic', __bind(function() {
            if (child.type === 'test' && this._errorPattern.test(child.content)) {
              return child.run([null].concat(this.topics));
            } else {
              return child.run(this.topics);
            }
          }, this));
          this.on('error', __bind(function(e) {
            if (child.type === 'test' && this._errorPattern.test(child.content)) {
              return child.run(arguments);
            } else {
              child.exception = e;
              return child.end('errored');
            }
          }, this));
          return child.on('end', __bind(function(result) {
            if (!--this.results.running) {
              return this.end('done');
            }
          }, this));
        }, this);
        for (key in _ref2) {
          child = _ref2[key];
          _fn(child);
        }
        this.on('topic', __bind(function() {
          if (this.teardown != null) {
            return this.teardown.apply(this, this.topics);
          }
        }, this));
        if (!(this.topic != null)) {
          if (this.topics.length) {
            this.topic = this.topics[0];
          }
        } else if (typeof this.topic === 'function') {
          try {
            this.topic = this.topic.apply(this.env, this.topics);
            if (!(this.topic != null)) {
              this.async = true;
            } else if (this.async) {
              this.topic = null;
            }
          } catch (e) {
            this.error(e);
            return this;
          }
        }
        if (this.topic != null) {
          if (this.topic instanceof events.EventEmitter) {
            this.async = true;
            this.topic.on('success', __bind(function() {
              return this.success.apply(this, arguments);
            }, this));
            this.topic.on('error', __bind(function() {
              return this.error.apply(this, arguments);
            }, this));
          } else {
            this.async = false;
            this.success(this.topic);
          }
        } else if (!this.async) {
          this.success();
        }
    }
    return this;
  };
  Context.prototype.end = function(result) {
    var context, key, parts, _i, _len, _ref, _ref2, _ref3;
    if ((_ref = this.status) === 'end') {
      throw new vows.VowsError(this, 'The \'end\' event was triggered twice');
    }
    this.result = result;
    this.results.endDate = new Date;
    this.results.duration = (this.results.endDate - this.results.startDate) / 1000;
    if (this.type === 'group') {
      if (this.result === 'errored' && !this.hasTests) {
        context = this;
        parts = [this.description];
        while ((context = context.parent) && context.parent !== vows.runner) {
          if (context.description) {
            parts.unshift(context.description);
          }
        }
        this.report('context', {
          description: parts.join(' '),
          exception: this.exception
        });
      }
    }
    if ((_ref2 = this.type) === 'test' || _ref2 === 'comment') {
      this.results[this.result]++;
      this.report('vow', {
        description: this.description,
        content: this.content,
        context: this.parent.description,
        result: this.result,
        duration: this.results.duration,
        exception: this.exception
      });
    }
    if (this.parent != null) {
      _ref3 = ['running', 'honored', 'pending', 'broken', 'errored'];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        key = _ref3[_i];
        this.parent.results[key] += this.results[key];
      }
    }
    this.emit(this.status = 'end', this.result);
    return this;
  };
  Context.prototype.success = function() {
    var args;
    args = Array.prototype.slice.call(arguments);
    args.unshift(null);
    return this.callback.apply(this, args);
  };
  Context.prototype.error = function() {
    var args;
    args = Array.prototype.slice.call(arguments);
    if (!args.length) {
      args.unshift(new Error('Unspecified error'));
    }
    return this.callback.apply(this, args);
  };
  Context.prototype.callback = function() {
    var args, e, _ref;
    if ((_ref = this.status) === 'run' || _ref === 'end') {
      if (this.async) {
        throw new vows.VowsError(this, 'An asynchronous callback was made after a value was returned.');
      } else {
        throw new vows.VowsError(this, 'An asynchronous callback was made twice.');
      }
    }
    this.emit(this.status = 'run');
    args = Array.prototype.slice.call(arguments);
    e = args.shift();
    if (typeof e === 'boolean' && !args.length) {
      this.emit('topic', e);
    } else if (e != null) {
      this.exception = e;
      this.emit.apply(this, ['error', e].concat(args));
    } else {
      this.emit.apply(this, ['topic'].concat(args));
    }
  };
  Context.prototype.add = function(context) {
    switch (this.type) {
      case 'batch':
        this.content.push(context);
        break;
      case 'group':
        this.content[context.description] = context;
        break;
      default:
        throw new vows.VowsError(this, 'Can\'t add to tests or comments');
    }
    context.parent = this;
    this.results.total += context.results.total;
    return this;
  };
  Context.prototype["export"] = function(module, options) {
    return module.exports[this.description] = this;
  };
  Context.prototype.exportTo = Context.prototype["export"];
  Context.prototype.addBatch = Context.prototype.add;
  return Context;
})();
vows.Runner = (function() {
  __extends(Runner, vows.Context);
  function Runner() {
    Runner.__super__.constructor.apply(this, arguments);
  }
  Runner.prototype._totalTests = function() {
    var child, groupTotal, key, _ref;
    switch (this.type) {
      case 'group':
        groupTotal = 0;
        _ref = this.content;
        for (key in _ref) {
          child = _ref[key];
          groupTotal += this.content[key].type === 'test';
        }
    }
  };
  Runner.prototype.run = function(callback) {
    this.on('end', __bind(function() {
      this.results.dropped = this.results.total - (this.results.honored + this.results.pending + this.results.errored + this.results.broken);
      this.report('finish', this.results);
      if (callback != null) {
        return callback(this.results);
      }
    }, this));
    return Runner.__super__.run.call(this);
  };
  return Runner;
})();
vows.runner = new vows.Runner(null, []);
vows.stylizers = stylizers = {};
vows.stylize = function(ob) {
  var arg, s, _i, _len, _ref;
  s = new vows.stylizer(ob);
  _ref = Array.prototype.slice.call(arguments).slice(1);
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    arg = _ref[_i];
    s.stylize(arg);
  }
  return s;
};
vows.format = function(str) {
  str = str.replace(/`([^`]+)`/g, __bind(function(_, part) {
    return vows.stylize(part).italic();
  }, this));
  str = str.replace(/\*([^*]+)\*/g, __bind(function(_, part) {
    return vows.stylize(part).bold();
  }, this));
  str = str.replace(/_([^_]+)_/g, __bind(function(_, str) {
    return vows.stylize(part).underline();
  }, this));
  return str;
};
_stack = [];
vows.stringify = function(obj) {
  var before, contents, end, i, k, len, o, pretty, result, sep, start, typeOf, v;
  len = function(obj) {
    return obj.length('length' in obj ? void 0 : Object.keys(obj).length);
  };
  typeOf = function(value) {
    var s, type, types, _i, _len;
    s = typeof value;
    types = [Object, Array, String, RegExp, Number, Function, Boolean, Date];
    if (s === 'object' || s === 'function') {
      if (value != null) {
        for (_i = 0, _len = types.length; _i < _len; _i++) {
          type = types[_i];
          if (value instanceof type) {
            s = type.name.toLowerCase();
          }
        }
      } else {
        s = 'null';
      }
    }
    return s;
  };
  if (__indexOf.call(_stack, obj) >= 0) {
    before = _stack.length - _stack.indexOf(obj);
    return vows.stylize(((function() {
      var _results;
      _results = [];
      for (i = 0; 0 <= before ? i <= before : i >= before; 0 <= before ? i++ : i--) {
        _results.push('.');
      }
      return _results;
    })()).join(''), 'special');
  }
  _stack.push(obj);
  result = (function() {
    switch (typeOf(obj)) {
      case 'regexp':
        return vows.stylize('/' + obj.source + '/', 'regexp');
      case 'number':
        return vows.stylize(obj.toString(), 'number');
      case 'boolean':
        return vows.stylize(obj.toString(), 'boolean');
      case 'null':
        return vows.stylize('null', 'special');
      case 'undefined':
        return vows.stylize('undefined', 'special');
      case 'function':
        return vows.stylize('[Function]', 'other');
      case 'date':
        return vows.stylize(obj.toUTCString(), 'default');
      case 'string':
        obj = /'/.test(obj) ? "\"" + obj + "\"" : "'" + obj + "'";
        obj = obj.replace(/\\/g, '\\\\').replace(/\n/g, '\\n').replace(/[\u0001-\u001F]/g, function(match) {
          return '\\0' + match[0].charCodeAt(0).toString(8);
        });
        return vows.stylize(obj, 'string');
      case 'array':
        pretty = len(obj) > 4 || len((function() {
          var _i, _len, _results;
          if (len(o) > 0) {
            _results = [];
            for (_i = 0, _len = obj.length; _i < _len; _i++) {
              o = obj[_i];
              _results.push(o);
            }
            return _results;
          }
        })());
        start = pretty ? '\n' + ((function() {
          var _ref, _results;
          _results = [];
          for (i = 0, _ref = 4 * _stack.length; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
            _results.push(' ');
          }
          return _results;
        })()).join('') : ' ';
        end = pretty ? ws.slice(0, -4) : ' ';
        sep = "," + start;
        contents = ((function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = obj.length; _i < _len; _i++) {
            o = obj[_i];
            _results.push(vows.stringify(o));
          }
          return _results;
        })()).join(sep);
        if (contents) {
          return "[" + start + contents + end + "]";
        } else {
          return '[]';
        }
        break;
      case 'object':
        pretty = len(obj) > 2 || len((function() {
          var _i, _len, _ref, _results;
          _ref = obj && len(o) > 0;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            o = _ref[_i];
            _results.push(o);
          }
          return _results;
        })());
        start = pretty ? '\n' + ((function() {
          var _ref, _results;
          _results = [];
          for (i = 0, _ref = 4 * _stack.length; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
            _results.push(' ');
          }
          return _results;
        })()).join('') : ' ';
        end = pretty ? ws.slice(0, -4) : ' ';
        sep = "," + start;
        contents = ((function() {
          var _results;
          _results = [];
          for (k in obj) {
            v = obj[k];
            _results.push(vows.stylize(k).key() + ': ' + vows.stringify(v));
          }
          return _results;
        })()).join(sep);
        if (contents) {
          return "{" + start + contents + end + "}";
        } else {
          return '{}';
        }
    }
  })();
  _stack.pop();
  return result;
};
stylizers.BaseStylizer = (function() {
  function BaseStylizer(ob) {
    this.str = '' + ob;
  }
  BaseStylizer.prototype.toString = function() {
    return this.str;
  };
  return BaseStylizer;
})();
stylizers.ConsoleStylizer = (function() {
  var k, style, v, _fn, _ref;
  __extends(ConsoleStylizer, stylizers.BaseStylizer);
  function ConsoleStylizer() {
    ConsoleStylizer.__super__.constructor.apply(this, arguments);
  }
  ConsoleStylizer.prototype.styles = {
    plain: null,
    bold: [1, 22],
    light: [2, 22],
    italic: [3, 23],
    underline: [4, 24],
    negative: [7, 27],
    concealed: [8, 28],
    struck: [9, 29],
    black: [30, 39],
    red: [31, 39],
    green: [32, 39],
    yellow: [33, 39],
    blue: [34, 39],
    magenta: [35, 39],
    cyan: [36, 39],
    white: [37, 39],
    grey: [90, 39]
  };
  ConsoleStylizer.prototype.mapping = {
    success: 'green',
    error: 'red',
    warning: 'yellow',
    pending: 'cyan',
    message: 'grey',
    result: 'plain',
    label: 'underline',
    key: 'bold',
    string: 'green',
    number: 'magenta',
    boolean: 'blue',
    special: 'grey',
    regexp: 'green',
    "function": 'negative',
    comment: 'cyan'
  };
  _ref = ConsoleStylizer.prototype.mapping;
  for (k in _ref) {
    v = _ref[k];
    ConsoleStylizer.prototype.styles[k] = ConsoleStylizer.prototype.styles[v];
  }
  _fn = __bind(function(style) {
    return this.prototype[style] = function() {
      return this.stylize(style);
    };
  }, ConsoleStylizer);
  for (style in ConsoleStylizer.prototype.styles) {
    _fn(style);
  }
  ConsoleStylizer.prototype.stylize = function(style) {
    if (this.styles[style]) {
      this.str = "\033[" + this.styles[style][0] + "m" + this.str + "\033[" + this.styles[style][1] + "m";
    }
    return this;
  };
  return ConsoleStylizer;
}).call(this);
stylizers.HTMLStylizer = (function() {
  var c, style, _fn, _i, _j, _len, _len2, _ref, _ref2;
  __extends(HTMLStylizer, stylizers.BaseStylizer);
  function HTMLStylizer() {
    HTMLStylizer.__super__.constructor.apply(this, arguments);
  }
  HTMLStylizer.prototype.styles = {
    bold: ['b', null],
    italic: ['i', null],
    underline: ['u', null]
  };
  HTMLStylizer.prototype.divs = ['success', 'error', 'warning', 'pending', 'result', 'message'];
  HTMLStylizer.prototype.spans = ['label', 'key', 'string', 'number', 'boolean', 'special', 'regexp', 'function', 'comment'];
  _ref = HTMLStylizer.prototype.divs;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    c = _ref[_i];
    HTMLStylizer.prototype.styles[c] = ['div', c];
  }
  _ref2 = HTMLStylizer.prototype.spans;
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    c = _ref2[_j];
    HTMLStylizer.prototype.styles[c] = ['span', c];
  }
  _fn = __bind(function(style) {
    return this.prototype[style] = function() {
      return this.stylize(style);
    };
  }, HTMLStylizer);
  for (style in HTMLStylizer.prototype.styles) {
    _fn(style);
  }
  HTMLStylizer.prototype.stylize = function(style) {
    var classAttr, className, tagName, _ref3;
    _ref3 = this.styles[style], tagName = _ref3[0], className = _ref3[1];
    classAttr = className ? " class=\"" + className + "\"" : "";
    this.str = "<" + tagName + classAttr + ">" + this.str + "</" + tagName + ">";
    return this;
  };
  return HTMLStylizer;
}).call(this);
vows.reporters = reporters = {};
vows.report = function() {
  if (vows.reporter) {
    return vows.reporter.report.apply(vows.reporter, arguments);
  }
};
reporters.BaseReporter = (function() {
  BaseReporter.prototype.name = 'silent';
  function BaseReporter() {
    this.reset();
  }
  BaseReporter.prototype.reset = function() {
    return null;
  };
  BaseReporter.prototype.report = function(data) {
    return null;
  };
  BaseReporter.prototype.print = function(ob) {
    return process.stdout.write('' + ob);
  };
  BaseReporter.prototype.stylize = function(ob) {
    return vows.stylize(ob);
  };
  return BaseReporter;
})();
reporters.JSONReporter = (function() {
  __extends(JSONReporter, reporters.BaseReporter);
  function JSONReporter() {
    JSONReporter.__super__.constructor.apply(this, arguments);
  }
  JSONReporter.prototype.name = 'json';
  JSONReporter.prototype.report = function() {
    return this.print(JSON.stringify(Array.prototype.slice.call(arguments)) + '\n');
  };
  return JSONReporter;
})();
reporters.SpecReporter = (function() {
  __extends(SpecReporter, reporters.BaseReporter);
  function SpecReporter() {
    SpecReporter.__super__.constructor.apply(this, arguments);
  }
  SpecReporter.prototype.name = 'spec';
  SpecReporter.prototype.report = function(name, event) {
    switch (name) {
      case 'subject':
        return this.print("\n\n♢ " + (this.stylize(event).bold()) + "\n");
      case 'context':
        return this.print(this._contextEvent(event));
      case 'vow':
        return this.print(this._vowEvent(event));
      case 'end':
        return this.print('\n');
      case 'finish':
        return this.print('\n' + this._resultEvent(event));
      case 'error':
        return this.print(this._errorEvent(event));
    }
  };
  SpecReporter.prototype._contextEvent = function(event) {
    if (event.exception) {
      return this.stylize("\n  " + event.description + "\n").error();
    } else {
      return "\n  " + event.description + "\n";
    }
  };
  SpecReporter.prototype._vowEvent = function(event) {
    switch (event.result) {
      case 'honored':
        return this.stylize("    ✓ " + event.description + "\n").success();
      case 'broken':
        return this.stylize("    ✗ " + event.description + "\n      » " + event.exception + "\n").warning();
      case 'errored':
        return this.stylize("    ⊘ " + event.description + "\n      » " + event.exception + "\n").error();
      case 'pending':
        return this.stylize("    ∴ " + event.description + "\n      » " + event.content + "\n").pending();
    }
  };
  SpecReporter.prototype._resultEvent = function(event) {
    var header, key, message, status, time, _i, _len, _ref;
    if (event.total === 0) {
      return this.stylize('Could not find any tests to run.\n').bold().error();
    }
    status = (event.errored && 'errored') || (event.dropped && 'dropped') || (event.broken && 'broken') || (event.honored && 'honored') || (event.pending && 'pending');
    header = (function() {
      switch (status) {
        case 'errored':
          return this.stylize("⊘ " + (this.stylize('Errored').bold())).error();
        case 'dropped':
          return this.stylize("… " + (this.stylize('Incomplete').bold())).error();
        case 'broken':
          return this.stylize("✗ " + (this.stylize('Broken').bold())).warning();
        case 'honored':
          return this.stylize("✓ " + (this.stylize('Honored').bold())).success();
        case 'pending':
          return this.stylize("∴ " + (this.stylize('Pending').bold())).pending();
      }
    }).call(this);
    message = [];
    _ref = ['honored', 'pending', 'broken', 'errored', 'dropped'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      if (event[key]) {
        message.push("" + (this.stylize(event[key]).bold()) + " " + key);
      }
    }
    time = this.stylize(event.duration.toFixed(3)).message();
    return this.stylize("" + header + " » " + (message.join(' ∙ ')) + " (" + time + ")\n").result();
  };
  SpecReporter.prototype._errorEvent = function(event) {
    return ("✗ " + (this.stylize('Errored').error()) + " ") + ("» " + (this.stylize(vow.description).bold())) + (": " + (this.stylize(vow.exception).error()) + "\n");
  };
  return SpecReporter;
})();
reporters.DotMatrixReporter = (function() {
  __extends(DotMatrixReporter, reporters.SpecReporter);
  function DotMatrixReporter() {
    DotMatrixReporter.__super__.constructor.apply(this, arguments);
  }
  DotMatrixReporter.prototype.name = 'dot-matrix';
  DotMatrixReporter.prototype.reset = function() {
    this.messages = [];
    return this.lastContext = null;
  };
  DotMatrixReporter.prototype.report = function(name, event) {
    switch (name) {
      case 'subject':
        return null;
      case 'context':
        return null;
      case 'vow':
        switch (event.result) {
          case 'honored':
            return this.print(this.stylize('·').success());
          case 'pending':
            return this.print(this.stylize('-').pending());
          case 'broken':
          case 'errored':
            if (this.lastContext !== event.context) {
              this.lastContext = event.context;
              this.messages.push("  " + event.context);
            }
            this.print(this.stylize('✗', event.result === 'broken' ? 'warning' : 'error'));
            return this.messages.push(this._vowEvent(event));
        }
        break;
      case 'end':
        return this.print(' ');
      case 'finish':
        if (this.messages.length) {
          this.print('\n\n' + this.messages.join('\n') + '\n');
        } else {
          this.print('\n');
        }
        return this.print(this._resultEvent(event) + '\n');
      case 'error':
        return this.print(this._errorEvent(event));
    }
  };
  return DotMatrixReporter;
})();
reporters.HTMLSpecReporter = (function() {
  __extends(HTMLSpecReporter, reporters.SpecReporter);
  function HTMLSpecReporter() {
    HTMLSpecReporter.__super__.constructor.apply(this, arguments);
  }
  HTMLSpecReporter.prototype.name = 'html-spec';
  HTMLSpecReporter.prototype.print = function(ob) {
    return document.getElementById('vows-results').innerHTML += ob;
  };
  return HTMLSpecReporter;
})();
assert = require('assert');
assert.AssertionError.prototype.toString = function() {
  var line, message, source;
  if (this.stack) {
    source = this.stack.match(/([a-zA-Z0-9_-]+\.js)(:\d+):\d+/);
  }
  if (this.message) {
    message = vows.stylize(this.message.replace(/{actual}/g, vows.stringify(this.actual)).replace(/{operator}/g, vows.stylize(this.operator).bold()).replace(/{expected}/g, vows.stringify(this.expected))).warning();
    line = source ? vows.stylize(" // " + source[1] + source[2]).comment() : '';
    return message + line;
  } else {
    return vows.stylize([this.expected, this.operator, this.actual].join(' ')).warning();
  }
};
assert.matches = assert.match = function(actual, expected, message) {
  if (!expected.test(actual)) {
    return assert.fail(actual, expected, message, 'match', assert.match);
  }
};
assert.isTrue = function(actual, message) {
  if (actual !== true) {
    return assert.fail(actual, true, message, '===', assert.isTrue);
  }
};
assert.isFalse = function(actual, message) {
  if (actual !== false) {
    return assert.fail(actual, false, message, '===', assert.isFalse);
  }
};
assert.isZero = function(actual, message) {
  if (actual !== 0) {
    return assert.fail(actual, 0, message, '===', assert.isZero);
  }
};
assert.isNotZero = function(actual, message) {
  if (actual === 0) {
    return assert.fail(actual, 0, message, '===', assert.isNotZero);
  }
};
assert.greater = function(actual, expected, message) {
  if (!(actual > expected)) {
    return assert.fail(actual, expected, message, '>', assert.greater);
  }
};
assert.lesser = function(actual, expected, message) {
  if (!(actual < expected)) {
    return assert.fail(actual, expected, message, '<', assert.lesser);
  }
};
assert.includes = assert.include = function(actual, expected, message) {
  if (!((isArray(actual) || isString(actual) && actual.indexOf(expected) !== -1) || (isObject(actual) && actual.hasOwnProperty(expected)))) {
    return assert.fail(actual, expected, message, 'include', assert.include);
  }
};
assert.isEmpty = function(actual, message) {
  var key;
  if (!((isObject(actual) && ((function() {
    var _results;
    _results = [];
    for (key in actual) {
      _results.push(key);
    }
    return _results;
  })()).length === 0) || actual.length === 0)) {
    return assert.fail(actual, 0, message, 'length', assert.isEmpty);
  }
};
assert.length = function(actual, expected, message) {
  if (!actual.length === expected) {
    return assert.fail(actual, expected, message, 'length', assert.length);
  }
};
assert.isNull = function(actual, message) {
  if (actual !== null) {
    return assert.fail(actual, null, message, '===', assert.isNull);
  }
};
assert.isNotNull = function(actual, message) {
  if (actual === null) {
    return assert.fail(actual, null, message, '===', assert.isNotNull);
  }
};
assert.isUndefined = function(actual, message) {
  if (actual !== void 0) {
    return assert.fail(actual, void 0, message, '===', assert.isUndefined);
  }
};
assert.isNumber = function(actual, message) {
  if (isNaN(actual)) {
    return assert.fail(actual, 'number', message || 'expected {actual} to be of type {expected}', 'isNaN', assert.isNumber);
  } else {
    return assertTypeOf(actual, 'number', message || 'expected {actual} to be a Number', assert.isNumber);
  }
};
assert.isNaN = function(actual, message) {
  if (!actual === actual) {
    return assert.fail(actual, 'NaN', message, '===', assert.isNaN);
  }
};
assert.isArray = function(actual, message) {
  return assertTypeOf(actual, 'array', message, assert.isArray);
};
assert.isObject = function(actual, message) {
  return assertTypeOf(actual, 'object', message, assert.isObject);
};
assert.isString = function(actual, message) {
  return assertTypeOf(actual, 'string', message, assert.isString);
};
assert.isFunction = function(actual, message) {
  return assertTypeOf(actual, 'function', message, assert.isFunction);
};
assert.typeOf = function(actual, expected, message) {
  return assertTypeOf(actual, expected, message, assert.typeOf);
};
assert.instanceOf = function(actual, expected, message) {
  if (!(actual instanceof expected)) {
    return assert.fail(actual, expected, message, 'instanceof', assert.instanceOf);
  }
};
assertTypeOf = function(actual, expected, message, caller) {
  if (typeOf(actual) !== expected) {
    return assert.fail(actual, expected, message || 'expected {actual} to be of type {expected}', 'typeOf', caller);
  }
};
isArray = (_ref = Array.isArray) != null ? _ref : (function(obj) {
  return Object.prototype.toString.call(obj) === '[object Array]';
});
isString = function(obj) {
  return typeof obj === 'string' || obj instanceof String;
};
isObject = function(obj) {
  return typeof obj === 'object' && obj && !isArray(obj);
};
typeOf = function(value) {
  var s, type, types, _i, _len;
  s = typeof value;
  types = [Object, Array, String, RegExp, Number, Function, Boolean, Date];
  if (s === 'object' || s === 'function') {
    if (value) {
      for (_i = 0, _len = types.length; _i < _len; _i++) {
        type = types[_i];
        if (value instanceof type) {
          s = type.name.toLowerCase();
        }
      }
    } else {
      s = 'null';
    }
  }
  return s;
};
defaultMessages = {
  1: {
    'ok': 'expected a truthy expression, got {actual}',
    'isTrue': 'expected {expected}, got {actual}',
    'isFalse': 'expected {expected}, got {actual}',
    'isZero': 'expected {expected}, got {actual}',
    'isNotZero': 'expected non-zero value, got {actual}',
    'isEmpty': 'expected {actual} to be empty',
    'isNaN': 'expected {actual} to be NaN',
    'isNull': 'expected {expected}, got {actual}',
    'isNotNull': 'expected non-null value, got {actual}',
    'isUndefined': 'expected {actual} to be {expected}',
    'isArray': 'expected {actual} to be an Array',
    'isObject': 'expected {actual} to be an Object',
    'isString': 'expected {actual} to be a String',
    'isFunction': 'expected {actual} to be a Function'
  },
  2: {
    'instanceOf': 'expected {actual} to be an instance of {expected}',
    'equal': 'expected {expected},\n\tgot\t {actual} ({operator})',
    'strictEqual': 'expected {expected},\n\tgot\t {actual} ({operator})',
    'deepEqual': 'expected {expected},\n\tgot\t {actual} ({operator})',
    'notEqual': 'didn\'t expect {actual} ({operator})',
    'notStrictEqual': 'didn\'t expect {actual} ({operator})',
    'notDeepEqual': 'didn\'t expect {actual} ({operator})',
    'match': 'expected {actual} to match {expected}',
    'matches': 'expected {actual} to match {expected}',
    'include': 'expected {actual} to include {expected}',
    'includes': 'expected {actual} to include {expected}',
    'greater': 'expected {actual} to be greater than {expected}',
    'lesser': 'expected {actual} to be lesser than {expected}',
    'length': 'expected {actual} to have {expected} element(s)'
  }
};
for (n in defaultMessages) {
  defaults = defaultMessages[n];
  for (key in defaults) {
    defaultMessage = defaults[key];
    callback = assert[key];
    assert[key] = (function(n, key, defaultMessage, callback) {
      return function() {
        var args, _ref2;
        args = Array.prototype.slice.call(arguments);
        while (args.length <= n) {
          args.push(void 0);
        }
        if ((_ref2 = args[n]) == null) {
          args[n] = defaultMessage;
        }
        return callback.apply(null, args);
      };
    })(n, key, defaultMessage, callback);
  }
}
if (typeof document !== "undefined" && document !== null) {
  vows.reporter = new vows.reporters.HTMLSpecReporter;
  vows.stylizer = vows.stylizers.HTMLStylizer;
}
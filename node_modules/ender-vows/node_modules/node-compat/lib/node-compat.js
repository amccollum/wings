var assert, deepEqual, equal, events, expectedException, fail, isArguments, isArray, modules, notDeepEqual, notEqual, notStrictEqual, objEquiv, ok, process, streams, strictEqual, _deepEqual, _nextTickCallback, _nextTickQueue, _ref, _ref2, _ref3, _throws;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
}, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
assert = typeof provide !== "undefined" && provide !== null ? provide('assert', {}) : (this.assert = {});
assert.AssertionError = (function() {
  __extends(AssertionError, Error);
  function AssertionError(options) {
    var stackStartFunction;
    this.name = 'AssertionError';
    this.message = options.message;
    this.actual = options.actual;
    this.expected = options.expected;
    this.operator = options.operator;
    stackStartFunction = options.stackStartFunction || fail;
    if (Error.captureStackTrace != null) {
      Error.captureStackTrace(this, stackStartFunction);
    }
  }
  AssertionError.prototype.toString = function() {
    if (this.message) {
      return [this.name + ':', this.message].join(' ');
    } else {
      return [this.name + ':', JSON.stringify(this.expected), this.operator, JSON.stringify(this.actual)].join(' ');
    }
  };
  return AssertionError;
})();
assert.fail = fail = function(actual, expected, message, operator, stackStartFunction) {
  throw new assert.AssertionError({
    message: message,
    actual: actual,
    expected: expected,
    operator: operator,
    stackStartFunction: stackStartFunction
  });
};
assert.ok = ok = function(value, message) {
  if (!!!value) {
    return fail(value, true, message, '==', assert.ok);
  }
};
assert.equal = equal = function(actual, expected, message) {
  if (actual != expected) {
    return fail(actual, expected, message, '==', assert.equal);
  }
};
assert.notEqual = notEqual = function(actual, expected, message) {
  if (actual == expected) {
    return fail(actual, expected, message, '!=', assert.notEqual);
  }
};
assert.deepEqual = deepEqual = function(actual, expected, message) {
  if (!_deepEqual(actual, expected)) {
    return fail(actual, expected, message, 'deepEqual', assert.deepEqual);
  }
};
_deepEqual = function(actual, expected) {
  if (actual === expected) {
    return true;
  }
  if (actual instanceof Date && expected instanceof Date) {
    return actual.getTime() === expected.getTime();
  }
  if (typeof actual !== 'object' && typeof expected !== 'object') {
    return actual == expected;
  }
  return objEquiv(actual, expected);
};
isArguments = function(object) {
  return Object.prototype.toString.call(object) === '[object Arguments]';
};
objEquiv = function(a, b) {
  var i, ka, kb, _ref, _ref2;
  if (!((a != null) && (b != null))) {
    return false;
  }
  if (a.prototype !== b.prototype) {
    return false;
  }
  if (isArguments(a)) {
    if (!isArguments(b)) {
      return false;
    }
    a = Array.prototype.slice.call(a);
    b = Array.prototype.slice.call(b);
    return _deepEqual(a, b);
  }
  try {
    ka = Object.keys(a);
    kb = Object.keys(b);
  } catch (e) {
    return false;
  }
  if (ka.length !== kb.length) {
    return false;
  }
  ka.sort();
  kb.sort();
  for (i = _ref = ka.length - 1; i >= 0; i += -1) {
    if (ka[i] !== kb[i]) {
      return false;
    }
  }
  for (i = _ref2 = ka.length - 1; i >= 0; i += -1) {
    if (!_deepEqual(a[ka[i]], b[ka[i]])) {
      return false;
    }
  }
  return true;
};
assert.notDeepEqual = notDeepEqual = function(actual, expected, message) {
  if (_deepEqual(actual, expected)) {
    return fail(actual, expected, message, 'notDeepEqual', assert.notDeepEqual);
  }
};
assert.strictEqual = strictEqual = function(actual, expected, message) {
  if (actual !== expected) {
    return fail(actual, expected, message, '===', assert.strictEqual);
  }
};
assert.notStrictEqual = notStrictEqual = function(actual, expected, message) {
  if (actual === expected) {
    return fail(actual, expected, message, '!==', assert.notStrictEqual);
  }
};
expectedException = function(actual, expected) {
  if (!actual || !expected) {
    return false;
  }
  if (expected instanceof RegExp) {
    return expected.test(actual);
  } else if (actual instanceof expected) {
    return true;
  } else if (expected.call({}, actual) === true) {
    return true;
  }
  return false;
};
_throws = function(shouldThrow, block, expected, message) {
  var actual;
  if (typeof expected === 'string') {
    message = expected;
    expected = null;
  }
  try {
    block();
  } catch (e) {
    actual = e;
  }
  message = (expected && expected.name ? " (" + expected.name + ")." : '.') + (message ? ' ' + message : '.');
  if (shouldThrow && !(actual != null)) {
    fail('Missing expected exception' + message);
  }
  if (!shouldThrow && expectedException(actual, expected)) {
    fail('Got unwanted exception' + message);
  }
  if (!shouldThrow && actual) {
    throw actual;
  }
  if (shouldThrow && (actual != null) && (expected != null) && !expectedException(actual, expected)) {
    throw actual;
  }
};
assert.throws = function(block, error, message) {
  return _throws.apply(this, [true].concat(Array.prototype.slice.call(arguments)));
};
assert.doesNotThrow = function(block, error, message) {
  return _throws.apply(this, [false].concat(Array.prototype.slice.call(arguments)));
};
assert.ifError = function(err) {
  if (err) {
    throw err;
  }
};
events = typeof provide !== "undefined" && provide !== null ? provide('events', {}) : (this.events = {});
isArray = (_ref = Array.isArray) != null ? _ref : (function(obj) {
  return Object.prototype.toString.call(obj) === '[object Array]';
});
events.EventEmitter = (function() {
  function EventEmitter() {}
  EventEmitter.prototype.emit = function(type) {
    var args, listener, _i, _len, _ref2;
    if (!((this._events != null) && this._events[type] && this._events[type].length)) {
      return false;
    }
    args = Array.prototype.slice.call(arguments, 1);
    _ref2 = this._events[type];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      listener = _ref2[_i];
      listener.apply(this, args);
    }
    return true;
  };
  EventEmitter.prototype.addListener = function(type, listener) {
    this.emit('newListener', type, listener);
    this.listeners(type).push(listener);
    return this;
  };
  EventEmitter.prototype.on = EventEmitter.prototype.addListener;
  EventEmitter.prototype.once = function(type, listener) {
    var g;
    g = __bind(function() {
      return listener.apply(this.removeListener(type, g), arguments);
    }, this);
    this.on(type, g);
    return this;
  };
  EventEmitter.prototype.removeListener = function(type, listener) {
    var l;
    if (this._events && type in this._events) {
      this._events[type] = ((function() {
        var _i, _len, _ref2, _results;
        if (l !== listener) {
          _ref2 = this._events[type];
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            l = _ref2[_i];
            _results.push(l);
          }
          return _results;
        }
      }).call(this));
      if (this._events[type].length === 0) {
        delete this._events[type];
      }
    }
    return this;
  };
  EventEmitter.prototype.removeAllListeners = function(type) {
    if (this._events && type in this._events) {
      delete this._events[type];
    }
    return this;
  };
  EventEmitter.prototype.listeners = function(type) {
    var _ref2;
    if ((_ref2 = this._events) == null) {
      this._events = {};
    }
    if (!(type in this._events)) {
      this._events[type] = [];
    }
    return this._events[type];
  };
  return EventEmitter;
})();
modules = {};
if ((_ref2 = this.provide) == null) {
  this.provide = function(name, module) {
    return modules[name] = module;
  };
}
if ((_ref3 = this.require) == null) {
  this.require = function(name) {
    var _ref4;
    return (_ref4 = modules[name]) != null ? _ref4 : this[name];
  };
}
events = require('events');
streams = typeof provide !== "undefined" && provide !== null ? provide('streams', {}) : (this.streams = {});
streams.ReadableStream = (function() {
  __extends(ReadableStream, events.EventEmitter);
  function ReadableStream() {
    ReadableStream.__super__.constructor.apply(this, arguments);
  }
  ReadableStream.prototype.readable = false;
  ReadableStream.prototype.setEncoding = function() {
    throw new Error('Not Implemented');
  };
  ReadableStream.prototype.pause = function() {
    throw new Error('Not Implemented');
  };
  ReadableStream.prototype.resume = function() {
    throw new Error('Not Implemented');
  };
  ReadableStream.prototype.destroy = function() {
    throw new Error('Not Implemented');
  };
  return ReadableStream;
})();
streams.WriteableStream = (function() {
  __extends(WriteableStream, events.EventEmitter);
  function WriteableStream() {
    WriteableStream.__super__.constructor.apply(this, arguments);
  }
  WriteableStream.prototype.writeable = false;
  WriteableStream.prototype.write = function(string) {
    throw new Error('Not Implemented');
  };
  WriteableStream.prototype.end = function(string) {
    throw new Error('Not Implemented');
  };
  WriteableStream.prototype.destroy = function() {
    throw new Error('Not Implemented');
  };
  return WriteableStream;
})();
streams = require('streams');
process = typeof provide !== "undefined" && provide !== null ? provide('process', {}) : (this.process = {});
process.stdout = (function() {
  __extends(stdout, streams.WriteableStream);
  function stdout() {
    stdout.__super__.constructor.apply(this, arguments);
  }
  stdout.prototype.writeable = true;
  stdout.prototype.write = function(string) {
    if (this.writeable) {
      document.write(string);
    }
    return true;
  };
  stdout.prototype.end = function(string) {
    if (string) {
      write(string);
    }
    this.writeable = false;
    this.emit('close');
  };
  stdout.prototype.destroy = function() {
    this.writeable = false;
    this.emit('close');
  };
  return stdout;
})();
process.platform = navigator.platform;
_nextTickQueue = [];
_nextTickCallback = function() {
  var callback, i, _len;
  try {
    for (i = 0, _len = _nextTickQueue.length; i < _len; i++) {
      callback = _nextTickQueue[i];
      callback();
    }
    _nextTickQueue.splice(0, i);
    if (_nextTickQueue.length) {
      return setTimeout(_nextTickCallback, 1);
    }
  } catch (e) {
    _nextTickQueue.splice(0, i + 1);
    if (_nextTickQueue.length) {
      setTimeout(_nextTickCallback, 1);
    }
    throw e;
  }
};
process.nextTick = function(callback) {
  _nextTickQueue.push(callback);
  if (_nextTickQueue.length === 1) {
    return setTimeout(_nextTickCallback, 1);
  }
};
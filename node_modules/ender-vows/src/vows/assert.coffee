assert = require('assert')


assert.AssertionError.prototype.toString = () ->
    if @stack
        source = @stack.match(/([a-zA-Z0-9_-]+\.js)(:\d+):\d+/)

    if @message
        message = vows.stylize(@message.replace(/{actual}/g, vows.stringify(@actual))
                                       .replace(/{operator}/g, vows.stylize(@operator).bold())
                                       .replace(/{expected}/g, vows.stringify(@expected))).warning()
                          
        line = if source then vows.stylize(" // #{source[1]}#{source[2]}").comment() else ''
        return message + line
        
    else
        return vows.stylize([@expected, @operator, @actual].join(' ')).warning()


assert.matches = assert.match = (actual, expected, message) ->
    assert.fail(actual, expected, message, 'match', assert.match) if not expected.test(actual)

assert.isTrue = (actual, message) ->
    assert.fail(actual, true, message, '===', assert.isTrue) if actual != true

assert.isFalse = (actual, message) ->
    assert.fail(actual, false, message, '===', assert.isFalse) if actual != false

assert.isZero = (actual, message) ->
    assert.fail(actual, 0, message, '===', assert.isZero) if actual != 0

assert.isNotZero = (actual, message) ->
    assert.fail(actual, 0, message, '===', assert.isNotZero) if actual == 0

assert.greater = (actual, expected, message) ->
    assert.fail(actual, expected, message, '>', assert.greater) if not (actual > expected)

assert.lesser = (actual, expected, message) ->
    assert.fail(actual, expected, message, '<', assert.lesser) if not (actual < expected)

assert.includes = assert.include = (actual, expected, message) ->
    if not ((isArray(actual) or isString(actual) and actual.indexOf(expected) != -1) or
            (isObject(actual) and actual.hasOwnProperty(expected)))
        assert.fail(actual, expected, message, 'include', assert.include)

assert.isEmpty = (actual, message) ->
    if not ((isObject(actual) and (key for key of actual).length == 0) or actual.length == 0)
        assert.fail(actual, 0, message, 'length', assert.isEmpty)

assert.length = (actual, expected, message) ->
    assert.fail(actual, expected, message, 'length', assert.length) if not actual.length == expected

assert.isNull = (actual, message) ->
    assert.fail(actual, null, message, '===', assert.isNull) if actual != null

assert.isNotNull = (actual, message) ->
    assert.fail(actual, null, message, '===', assert.isNotNull) if actual == null

assert.isUndefined = (actual, message) ->
    assert.fail(actual, undefined, message, '===', assert.isUndefined) if actual != undefined

assert.isNumber = (actual, message) ->
    if isNaN(actual)
        assert.fail(actual, 'number', message or 'expected {actual} to be of type {expected}', 'isNaN', assert.isNumber)
    else
        assertTypeOf(actual, 'number', message or 'expected {actual} to be a Number', assert.isNumber)

assert.isNaN = (actual, message) ->
    assert.fail(actual, 'NaN', message, '===', assert.isNaN) if not actual == actual

assert.isArray = (actual, message) -> assertTypeOf(actual, 'array', message, assert.isArray)
assert.isObject = (actual, message) -> assertTypeOf(actual, 'object', message, assert.isObject)
assert.isString = (actual, message) -> assertTypeOf(actual, 'string', message, assert.isString)
assert.isFunction = (actual, message) -> assertTypeOf(actual, 'function', message, assert.isFunction)
assert.typeOf = (actual, expected, message) -> assertTypeOf(actual, expected, message, assert.typeOf)

assert.instanceOf = (actual, expected, message) ->
    assert.fail(actual, expected, message, 'instanceof', assert.instanceOf) if actual not instanceof expected

#
# Utility functions
#
assertTypeOf = (actual, expected, message, caller) ->
    if typeOf(actual) != expected
        assert.fail(actual, expected, message or 'expected {actual} to be of type {expected}', 'typeOf', caller)

isArray = Array.isArray ? ((obj) -> Object.prototype.toString.call(obj) == '[object Array]')
isString = (obj) -> typeof obj == 'string' or obj instanceof String
isObject = (obj) -> typeof obj == 'object' and obj and !isArray(obj)

# A better `typeof`
typeOf = (value) ->
    s = typeof value
    types = [Object, Array, String, RegExp, Number, Function, Boolean, Date]

    if s == 'object' or s == 'function'
        if value
            for type in types
                if value instanceof type
                    s = type.name.toLowerCase()
                
        else
            s = 'null'

    return s


defaultMessages = {
    1: {
        'ok':           'expected a truthy expression, got {actual}',
        'isTrue':       'expected {expected}, got {actual}',
        'isFalse':      'expected {expected}, got {actual}',
        'isZero':       'expected {expected}, got {actual}',
        'isNotZero':    'expected non-zero value, got {actual}',
        'isEmpty':      'expected {actual} to be empty',
        'isNaN':        'expected {actual} to be NaN',
        'isNull':       'expected {expected}, got {actual}',
        'isNotNull':    'expected non-null value, got {actual}',
        'isUndefined':  'expected {actual} to be {expected}',
        'isArray':      'expected {actual} to be an Array',
        'isObject':     'expected {actual} to be an Object',
        'isString':     'expected {actual} to be a String',
        'isFunction':   'expected {actual} to be a Function',
    },
    2: {
        'instanceOf':       'expected {actual} to be an instance of {expected}',
        'equal':            'expected {expected},\n\tgot\t {actual} ({operator})',
        'strictEqual':      'expected {expected},\n\tgot\t {actual} ({operator})',
        'deepEqual':        'expected {expected},\n\tgot\t {actual} ({operator})',
        'notEqual':         'didn\'t expect {actual} ({operator})',
        'notStrictEqual':   'didn\'t expect {actual} ({operator})',
        'notDeepEqual':     'didn\'t expect {actual} ({operator})',
        'match':            'expected {actual} to match {expected}',
        'matches':          'expected {actual} to match {expected}',
        'include':          'expected {actual} to include {expected}',
        'includes':         'expected {actual} to include {expected}',
        'greater':          'expected {actual} to be greater than {expected}',
        'lesser':           'expected {actual} to be lesser than {expected}',
        'length':           'expected {actual} to have {expected} element(s)',
    },
}

for n, defaults of defaultMessages
    for key, defaultMessage of defaults
        callback = assert[key]
        assert[key] = do (n, key, defaultMessage, callback) ->
            () ->
                args = Array.prototype.slice.call(arguments)
                while args.length <= n
                    args.push(undefined)
            
                args[n] ?= defaultMessage
                callback.apply(null, args)

# http:#wiki.commonjs.org/wiki/Unit_Testing/1.0
#
# THIS IS NOT TESTED NOR LIKELY TO WORK OUTSIDE V8!
#
# Originally from narwhal.js (http:#narwhaljs.org)
# Copyright (c) 2009 Thomas Robinson <280north.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

assert = if provide? then provide('assert', {}) else (@assert = {})

# 1. The assert module provides functions that throw
# AssertionError's when particular conditions are not met. The
# assert module must conform to the following interface.

# 2. The AssertionError is defined in assert.
# new assert.AssertionError({ message: message,
#                             actual: actual,
#                             expected: expected })
class assert.AssertionError extends Error
    constructor: (options) ->
        @name = 'AssertionError'
        @message = options.message
        @actual = options.actual
        @expected = options.expected
        @operator = options.operator
        stackStartFunction = options.stackStartFunction || fail

        if Error.captureStackTrace?
            Error.captureStackTrace(this, stackStartFunction)

    toString: () ->
        if this.message
            return [this.name + ':', this.message].join(' ')
        else
            return [this.name + ':',
                    JSON.stringify(this.expected),
                    this.operator,
                    JSON.stringify(this.actual)].join(' ')


# At present only the three keys mentioned above are used and
# understood by the spec. Implementations or sub modules can pass
# other keys to the AssertionError's constructor - they will be
# ignored.

# 3. All of the following functions must throw an AssertionError
# when a corresponding condition is not met, with a message that
# may be undefined if not provided.    All assertion methods provide
# both the actual and expected values to the assertion error for
# display purposes.

assert.fail = fail = (actual, expected, message, operator, stackStartFunction) ->
    throw new assert.AssertionError({
        message: message,
        actual: actual,
        expected: expected,
        operator: operator,
        stackStartFunction: stackStartFunction
    })

# 4. Pure assertion tests whether a value is truthy, as determined
# by !!guard.
# assert.ok(guard, message_opt)
# This statement is equivalent to assert.equal(true, guard,
# message_opt). To test strictly for the value true, use
# assert.strictEqual(true, guard, message_opt).

assert.ok = ok = (value, message) ->
    fail(value, true, message, '==', assert.ok) if not !!value


# 5. The equality assertion tests shallow, coercive equality with
# ==.
# assert.equal(actual, expected, message_opt)

assert.equal = equal = (actual, expected, message) ->
    fail(actual, expected, message, '==', assert.equal) if `actual != expected`

# 6. The non-equality assertion tests for whether two objects are not equal
# with != assert.notEqual(actual, expected, message_opt)

assert.notEqual = notEqual = (actual, expected, message) ->
    fail(actual, expected, message, '!=', assert.notEqual) if `actual == expected`

# 7. The equivalence assertion tests a deep equality relation.
# assert.deepEqual(actual, expected, message_opt)

assert.deepEqual = deepEqual = (actual, expected, message) ->
    fail(actual, expected, message, 'deepEqual', assert.deepEqual) if not _deepEqual(actual, expected)

_deepEqual = (actual, expected) ->
    # 7.1. All identical values are equivalent, as determined by ===.
    return true if actual == expected

    # 7.2. If the expected value is a Date object, the actual value is
    # equivalent if it is also a Date object that refers to the same time.
    if actual instanceof Date && expected instanceof Date
        return actual.getTime() == expected.getTime()

    # 7.3. Other pairs that do not both pass typeof value == 'object',
    # equivalence is determined by ==.
    if typeof actual != 'object' && typeof expected != 'object'
        return `actual == expected`

    # 7.4. For all other Object pairs, including Array objects, equivalence is
    # determined by having the same number of owned properties (as verified
    # with Object.prototype.hasOwnProperty.call), the same set of keys
    # (although not necessarily the same order), equivalent values for every
    # corresponding key, and an identical 'prototype' property. Note: this
    # accounts for both named and indexed properties on Arrays.
    return objEquiv(actual, expected)

isArguments = (object) -> (Object.prototype.toString.call(object) == '[object Arguments]')

objEquiv = (a, b) ->
    return false if not (a? and b?)
    
    # an identical 'prototype' property.
    return false if a.prototype != b.prototype

    #~~~I've managed to break Object.keys through screwy arguments passing.
    #     Converting to array solves the problem.
    if isArguments(a)
        if not isArguments(b)
            return false

        a = Array.prototype.slice.call(a)
        b = Array.prototype.slice.call(b)
        return _deepEqual(a, b)

    try
        ka = Object.keys(a)
        kb = Object.keys(b)
    catch e  # happens when one is a string literal and the other isn't
        return false

    # having the same number of owned properties (keys incorporates hasOwnProperty)
    return false if ka.length != kb.length

    #the same set of keys (although not necessarily the same order),
    ka.sort()
    kb.sort()

    #~~~cheap key test
    for i in [(ka.length-1)..0] by -1
        return false if ka[i] != kb[i]

    #equivalent values for every corresponding key, and
    #~~~possibly expensive deep test
    for i in [(ka.length-1)..0] by -1
        return false if not _deepEqual(a[ka[i]], b[ka[i]])

    return true


# 8. The non-equivalence assertion tests for any deep inequality.
# assert.notDeepEqual(actual, expected, message_opt)

assert.notDeepEqual = notDeepEqual = (actual, expected, message) ->
    fail(actual, expected, message, 'notDeepEqual', assert.notDeepEqual) if _deepEqual(actual, expected)

# 9. The strict equality assertion tests strict equality, as determined by ===.
# assert.strictEqual(actual, expected, message_opt)

assert.strictEqual = strictEqual = (actual, expected, message) ->
    fail(actual, expected, message, '===', assert.strictEqual) if actual != expected

# 10. The strict non-equality assertion tests for strict inequality, as
# determined by !==.    assert.notStrictEqual(actual, expected, message_opt)

assert.notStrictEqual = notStrictEqual = (actual, expected, message) ->
    fail(actual, expected, message, '!==', assert.notStrictEqual) if actual == expected

expectedException = (actual, expected) ->
    if not actual or not expected
        return false

    if expected instanceof RegExp
        return expected.test(actual)
    else if actual instanceof expected
        return true
    else if expected.call({}, actual) == true
        return true

    return false

_throws = (shouldThrow, block, expected, message) ->
    if typeof expected == 'string'
        message = expected
        expected = null

    try
        block()
    catch e
        actual = e

    message = (if expected and expected.name then " (#{expected.name})." else '.') +
              (if message then ' ' + message else '.')

    if shouldThrow and not actual?
        fail('Missing expected exception' + message)

    if not shouldThrow and expectedException(actual, expected)
        fail('Got unwanted exception' + message)

    if not shouldThrow and actual
        throw actual

    if shouldThrow and actual? and expected? and not expectedException(actual, expected)
        throw actual
    
# 11. Expected to throw an error:
# assert.throws(block, Error_opt, message_opt)

assert.throws = (block, error, message) ->
    _throws.apply(this, [true].concat(Array.prototype.slice.call(arguments)))

# EXTENSION! This is annoying to write outside this module.
assert.doesNotThrow = (block, error, message) ->
    _throws.apply(this, [false].concat(Array.prototype.slice.call(arguments)))

assert.ifError = (err) -> throw err if err

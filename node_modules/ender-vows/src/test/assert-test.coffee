assert = require('assert')
vows = require('..') ? require('vows')

vows.add 'vows/assert'
    'The Assertion module':
        topic: require('assert')

        '`equal`': (assert) ->
            assert.equal('hello world', 'hello world')
            assert.equal(1, true)

        '`match`': (assert) ->
            assert.match('hello world', /^[a-z]+ [a-z]+$/)
    
        '`length`': (assert) ->
            assert.length('hello world', 11)
            assert.length([1, 2, 3], 3)
    
        '`include`': (assert) ->
            assert.include('hello world', 'world')
            assert.include([0, 42, 0], 42)
            assert.include({goo:true}, 'goo')
    
        '`typeOf`': (assert) ->
            assert.typeOf('goo', 'string')
            assert.typeOf(42, 'number')
            assert.typeOf([], 'array')
            assert.typeOf({}, 'object')
            assert.typeOf(false, 'boolean')
    
        '`instanceOf`': (assert) ->
            assert.instanceOf([], Array)
            assert.instanceOf((() ->), Function)
    
        '`isArray`': (assert) ->
            assert.isArray([])
            assert.throws(() -> assert.isArray({}))
    
        '`isString`': (assert) ->
            assert.isString('')
    
        '`isObject`': (assert) ->
            assert.isObject({})
            assert.throws(() -> assert.isObject([]))
    
        '`isNumber`': (assert) ->
            assert.isNumber(0)
    
        '`isNan`': (assert) ->
            assert.isNaN(0/0)
    
        '`isTrue`': (assert) ->
            assert.isTrue(true)
            assert.throws(() -> assert.isTrue(1))
    
        '`isFalse`': (assert) ->
            assert.isFalse(false)
            assert.throws(() -> assert.isFalse(0))
    
        '`isZero`': (assert) ->
            assert.isZero(0)
            assert.throws(() -> assert.isZero(null))
    
        '`isNotZero`': (assert) ->
            assert.isNotZero(1)
    
        '`isUndefined`': (assert) ->
            assert.isUndefined(undefined)
            assert.throws(() -> assert.isUndefined(null))
    
        '`isNull`': (assert) ->
            assert.isNull(null)
            assert.throws(() -> assert.isNull(0))
            assert.throws(() -> assert.isNull(undefined))
    
        '`isNotNull`': (assert) ->
            assert.isNotNull(0)
    
        '`greater` and `lesser`': (assert) ->
            assert.greater(5, 4)
            assert.lesser(4, 5)
    
        '`isEmpty`': (assert) ->
            assert.isEmpty({})
            assert.isEmpty([])
            assert.isEmpty('')

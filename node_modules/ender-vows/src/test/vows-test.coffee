assert = require('assert')
events = require('events')
fs = require('fs')
vows = require('..') ? require('vows')

promiser = () ->
    args = Array.prototype.slice.call(arguments)
    promise = new events.EventEmitter
    process.nextTick () -> promise.emit.apply(promise, ['success'].concat(args))
    return promise

promiseBreaker = (val) ->
    args = Array.prototype.slice.call(arguments)
    promise = new events.EventEmitter
    process.nextTick () -> promise.emit.apply(promise, ['error'].concat(args))
    return promise


vows.add 'Vows', [
        'A context': 
            topic: () -> promiser('hello world')

            'with a nested context':
                topic: (parent) ->
                    @state = 42
                    return promiser(parent)
        
                'has access to the environment': () ->
                    assert.equal(@state, 42)
        
                'and a sub nested context': 
                    topic: () -> @state
            
                    'has access to the parent environment': (r) ->
                        assert.equal(r, 42)
                        assert.equal(@state, 42)
            
                    'has access to the parent context object': (r) ->
                        assert.isArray(@context.topics)
                        assert.include(@context.topics, 'hello world')


        'A nested context': 
            topic: () -> promiser(1),

            '.': 
                topic: (a) -> promiser(2) 

                '.': 
                    topic: (b, a) -> promiser(3) 

                    '.': 
                        topic: (c, b, a) -> promiser([4, c, b, a]) 

                        'should have access to the parent topics': (topics) ->
                            assert.equal(topics.join(), [4, 3, 2, 1].join())

                    'from': 
                        topic: (c, b, a) -> promiser([4, c, b, a]) 

                        'the parent topics': (topics) ->
                            assert.equal(topics.join(), [4, 3, 2, 1].join())


        'Nested contexts with callback-style async': 
            topic: () ->
                fs.stat(__dirname + '/vows-test.js', @callback)
    
            'after a successful `fs.stat`': 
                topic: (stat) ->
                    fs.open(__dirname + '/vows-test.js', 'r', stat.mode, @callback)
        
                'after a successful `fs.open`': 
                    topic: (fd, stat) ->
                        fs.read(fd, stat.size, 0, 'utf8', @callback)
            
                    'after a successful `fs.read`': (data) ->
                        assert.match(data, /after a successful `fs.read`/)


        'A nested context with no topics': 
            topic: 45,
            '.': 
                '.': 
                    'should pass the value down': (topic) ->
                        assert.equal(topic, 45)


        'A Nested context with topic gaps': 
            topic: 45,
            '.': 
                '.': 
                    topic: 101,
                    '.': 
                        '.': 
                            topic: (prev, prev2) -> @context.topics.slice()
                    
                            'should pass the topics down': (topics) ->
                                assert.length(topics, 2)
                                assert.equal(topics[0], 101)
                                assert.equal(topics[1], 45)


        'A non-promise return value': 
            topic: () -> 1 
            'should be converted to a promise': (val) ->
                assert.equal(val, 1)


        'A non-function topic': 
            topic: 45,

            'should work as expected': (topic) ->
                assert.equal(topic, 45)
    

        'A non-function topic with a falsy value': 
            topic: 0,

            'should work as expected': (topic) ->
                assert.equal(topic, 0)


        'A topic returning a function': 
            topic: () -> () -> 42 
    
            'should work as expected': (topic) ->
                assert.isFunction(topic)
                assert.equal(topic(), 42)
    
            'in a sub-context': 
                'should work as expected': (topic) ->
                    assert.isFunction(topic)
                    assert.equal(topic(), 42)
        

        'A topic emitting an error': 
            topic: () -> promiseBreaker(404)
    
            'shouldn\'t raise an exception if the test expects it': (e, res) ->
                assert.equal(e, 404)
                assert.ok(!res)
    

        'A topic not emitting an error': 
            topic: () -> promiser(true)
    
            'should pass `null` as first argument, if the test is expecting an error': (e, res) ->
                assert.strictEqual(e, null)
                assert.equal(res, true)
    
            'should pass the result as first argument if the test isn\'t expecting an error': (res) ->
                assert.equal(res, true)
    

        'A topic with callback-style async': 
            'when successful': 
                topic: () -> 
                    process.nextTick () => @callback(null, 'OK')
                    return
        
                'should work like an event-emitter': (res) ->
                    assert.equal(res, 'OK')
        
                'should assign `null` to the error argument': (e, res) ->
                    assert.strictEqual(e, null)
                    assert.equal(res, 'OK')
        
    
            'when unsuccessful': 
                topic: () -> ((callback) ->
                        process.nextTick () -> callback('ERROR')
                        return
                    )(@callback)
        
                'should have a non-null error value': (e, res) ->
                    assert.equal(e, 'ERROR')
        
                'should work like an event-emitter': (e, res) ->
                    assert.equal(res, undefined)
        
    
            'using @callback synchronously': 
                topic: () -> @callback(null, 'hello')
        
                'should work the same as returning a value': (res) ->
                    assert.equal(res, 'hello')

    , # New Group
        'A Sibling context': 
            '\'A\', with `@foo = true`': 
                topic: () ->
                    @foo = true
                    return this
            
                'should have `@foo` set to true': (res) ->
                    assert.equal(res.foo, true)
            
        
            '\'B\', with nothing set': 
                topic: () -> this
            
                'shouldn\'t have access to `@foo`': (e, res) ->
                    assert.isUndefined(res.foo)
            
    , # New Group
        'A 3rd group': 
            topic: () ->
                promise = new events.EventEmitter
                setTimeout(() ->
                    promise.emit('success')
                , 100)
                return promise
        
            'should run after the first': () ->

    , # New Group
        'A 4th group': 
            topic: true,
            'should run last': () ->
    ]


vows.add 'Vows with teardowns'
    'A context': 
        topic: () -> { flag: true }
    
        'And a vow': (topic) ->
            assert.isTrue(topic.flag)
    
        'And another vow': (topic) ->
            assert.isTrue(topic.flag)
    
        'And a final vow': (topic) ->
            assert.isTrue(topic.flag)
    
        teardown: (topic) ->
            topic.flag = false

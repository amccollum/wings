events = require('events')
assert = require('assert')
vows = require('..') ? require('vows')

vowPromiser = (description, content) ->
    promise = new events.EventEmitter
    context = new vows.Context(description, content, { silent: true })
    context.on 'end', () -> promise.emit('success', context)
    setTimeout((() -> context.end('timeout') if context.status == 'begin'), 100)
    process.nextTick () -> context.run()
    return promise


vows.add 'Vows Errors'
    'A pending test': 
        topic: () -> vowPromiser('A test', {
            'that is pending': 'pending'
        })
        
        'should have a pending result': (context) ->
            assert.equal context.results['total'], 1 
            assert.equal context.results['pending'], 1 

    'A test failing an assertion': 
        topic: () -> vowPromiser('A test', {
            topic: false
            'failing an assertion': (topic) -> assert.equal topic, true 
        })
        
        'should have a broken result': (context) ->
            assert.equal context.results['total'], 1 
            assert.equal context.results['broken'], 1 

    'A test throwing an error': 
        topic: () -> vowPromiser('A test', {
            topic: false
            'throwing an error': (topic) -> throw new Error('This is an error!')
        })
        
        'should have an errored result': (context) ->
            assert.equal context.results['total'], 1 
            assert.equal context.results['errored'], 1 

    'A topic synchronously throwing an error': 
        topic: () -> vowPromiser('A test', {
            topic: () -> throw new Error('This is an error!')
            'not expecting an error': (topic) -> assert.ok true  
            'expecting an error': (err, topic) -> assert.ok true  
        })
        
        'should error its tests that don\'t expect the error': (context) ->
            assert.equal context.results['total'], 2 
            assert.equal context.results['errored'], 1 

        'should pass its tests that do expect the error': (context) ->
            assert.equal context.results['total'], 2 
            assert.equal context.results['honored'], 1 

    'A topic asynchronously throwing an error': 
        topic: () -> vowPromiser('A test', {
            topic: () -> process.nextTick () => @error('This is an error!')
            'not expecting an error': (topic) -> assert.ok true  
            'expecting an error': (err, topic) -> assert.ok true  
        })
        
        'should error its tests that don\'t expect the error': (context) ->
            assert.equal context.results['total'], 2 
            assert.equal context.results['errored'], 1 

        'should pass its tests that do expect the error': (context) ->
            assert.equal context.results['total'], 2 
            assert.equal context.results['honored'], 1 

    'A test that never calls its callback': 
        topic: () -> vowPromiser('A test', {
            topic: () -> return
            'that never calls its callback': (topic) -> assert.ok null 
        })
        
        'should timeout': (context) ->
            assert.equal context.result, 'timeout' 
        
        'should still be running': (context) ->
            assert.equal context.results['total'], 1
            assert.equal context.results['running'], 1

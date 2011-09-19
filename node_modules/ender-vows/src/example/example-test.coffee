assert = require('assert')
vows = require('vows')

# Adding a test suite
vows.add 'Division by Zero'
    'when dividing a number by zero':
        topic: () -> return (42 / 0)

        'we get Infinity': (topic) ->
            assert.equal topic, Infinity

    'but when dividing zero by zero':
        topic: () -> return (0 / 0)

        'we get a value which':
            'is not a number': (topic) ->
                assert.isNaN topic
            
            'is not equal to itself': (topic) ->
                assert.notEqual topic, topic

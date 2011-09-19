# A basic implementation of the node.js EventEmitter class

events = if provide? then provide('events', {}) else (@events = {})

isArray = Array.isArray ? ((obj) -> Object.prototype.toString.call(obj) == '[object Array]')

class events.EventEmitter
    emit: (type) ->
        return false if not (@_events? and @_events[type] and @_events[type].length)
        args = Array.prototype.slice.call(arguments, 1)
        for listener in @_events[type]
            listener.apply(this, args)
            
        return true

    addListener: (type, listener) ->
        # Avoid recursion by firing the handler first
        @emit('newListener', type, listener)
        @listeners(type).push(listener)
        return this

    on: @prototype.addListener

    once: (type, listener) ->
        g = () => listener.apply(@removeListener(type, g), arguments)
        @on(type, g)
        return this

    removeListener: (type, listener) ->
        if @_events and type of @_events
            @_events[type] = (l for l in @_events[type] if l != listener)
            if @_events[type].length == 0
                delete @_events[type]
        
        return this

    removeAllListeners: (type) ->
        if @_events and type of @_events
            delete @_events[type]
        
        return this

    listeners: (type) ->
        @_events ?= {}
        @_events[type] = [] if type not of @_events
        return @_events[type]

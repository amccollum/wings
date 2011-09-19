streams = require('streams')
process = if provide? then provide('process', {}) else (@process = {})

class process.stdout extends streams.WriteableStream
    writeable: true
    write: (string) ->
        document.write(string) if @writeable
        return true
        
    end: (string) ->
        write(string) if string
        @writeable = false
        @emit('close')
        return
        
    destroy: () ->
        @writeable = false
        @emit('close')
        return
        
process.platform = navigator.platform

_nextTickQueue = []
_nextTickCallback = () ->
    try
        for callback, i in _nextTickQueue
            callback()
            
        _nextTickQueue.splice(0, i)
        if _nextTickQueue.length
            setTimeout(_nextTickCallback, 1)

    catch e
        _nextTickQueue.splice(0, i+1)
        if _nextTickQueue.length
            setTimeout(_nextTickCallback, 1)
            
        throw e
        
            
process.nextTick = (callback) ->
    _nextTickQueue.push(callback)
    if _nextTickQueue.length == 1
        setTimeout(_nextTickCallback, 1)

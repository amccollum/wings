events = require('events')
vows = require('vows')

vows.prepare = (ob, targets) ->
    for target in targets
        if target of ob
            ob[target] = vows.promise(ob[target])
            
    return ob

vows.promise = (fn) -> () -> (new vows.Promise(fn)).apply(this, arguments)


class vows.Promise extends events.EventEmitter
    constructor: (fn) ->
        @fn = fn
        
    call: () -> @apply(null, arguments)
    apply: (ob, args) ->
        args = Array.prototype.slice.call(args)
        args.push () =>
            [err, rest...] = Array.prototype.slice.call(arguments)
            @emit('error', err) if err
            @emit.apply(this, ['success'].concat(rest))
            
        @fn.apply(ob, args)
        return this


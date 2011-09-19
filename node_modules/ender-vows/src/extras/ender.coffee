!(($) ->
    vows = require('vows')
    ready = require('domready')
    
    ready () ->
        vows.run()
        return

)(ender)
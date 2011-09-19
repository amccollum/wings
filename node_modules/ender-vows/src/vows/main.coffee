events = require('events')
vows =
    if provide? then provide('vows', {})
    else if exports? then exports
    else (@vows = {})


# external API
vows.add = (description, tests, options) ->
    suite = new vows.Context(description, tests, options)
    vows.runner.add(suite)
    return suite
    
vows.describe = (description, options) -> vows.add(description, Array.prototype.slice.call(arguments, 1), options)
vows.run = () -> vows.runner.run()

class vows.VowsError extends Error
    constructor: (@context, @message) -> 
        @message = "#{@context.description}: #{@message}"
    toString: () -> "#{@context.description}: #{@message}"


class vows.Context extends events.EventEmitter
    constructor: (description, content, options, parent) ->
        @description = description
        @parent = parent

        # silence node EventEmitter warnings
        @_events = { maxListeners: 100 }

        @options = options ? {}
        @matched = (not @options.matcher?) or @parent?.matched or @options.matcher.test(@description)

        @results = { startDate: null, endDate: null }
        for key in ['total', 'running', 'honored', 'pending', 'broken', 'errored']
            @results[key] = 0

        switch typeof content
            when 'string'
                @type = 'comment'
                @results.total = 1
                @content = content
                
            when 'function'
                @type = 'test'
                @results.total = 1
                @content = content
                
            when 'object'
                if content.length?
                    @type = 'batch'
                    @content = []
                    
                    for value in content
                        @add(new vows.Context(null, value, @options, this))

                else
                    @type = 'group'
                    @content = {}
                    
                    for key, value of content
                        if key in ['topic', 'async', 'setup', 'teardown']
                            if key == 'topic'
                                @hasTopic = true
                                
                            @[key] = value
                            
                        else
                            @add(new vows.Context(key, value, @options, this))
                    
            else throw new vows.VowsError(this, 'Unknown content type')
            

    report: () -> vows.report.apply(this, arguments) if not @options.silent

    _errorPattern: /^function\s*\w*\s*\(\s*(e|err|error)\b/
    
    run: (topics) ->
        @topics = if topics? then Array.prototype.slice.call(topics) else []
        @results.startDate = new Date

        do =>
            # create the environment, inherited from the parent environment
            context = @
            @env = new class Env
                constructor: () ->
                    @context = context
                    @topics = context.topics
                    @success = () -> context.success.apply(context, arguments)
                    @error = () -> context.error.apply(context, arguments)
                    @callback = () -> context.callback.apply(context, arguments)
                
                # set the prototype to the parent environment
                @:: = (if context.parent then context.parent.env else {})
                @::constructor = @


        if @matched
            @emit(@status = 'begin')
        else
            @emit(@status = 'skip')
            return @end('skipped')

        if @parent == vows.runner
            @report('subject', @description) if @description

        switch @type
            when 'comment' then @end('pending')
            when 'test'
                try
                    @content.apply(@env, @topics)
                    @end('honored')
                        
                catch e
                    @exception = e
                    if e.name?.match(/AssertionError/)
                        @end('broken')
                    else
                        @end('errored')
             
            when 'batch'
                return @end('done') if not @content.length
                
                # run each item synchronously
                batch = @content.slice()
                while batch.length
                    cur = batch.pop()
                    
                    if next?
                        cur.on 'end', do (next) -> () -> next.run(topics)
                    else
                        # base case: end after the last child context ends
                        cur.on 'end', () => @end('done')
                    
                    next = cur

                cur.run(@topics)
        
            when 'group'
                return @end('end') if not (key for key of @content).length

                # setup
                if @setup?
                    try
                        @setup.apply(@env, @topics)
                    catch e
                        @exeption = e
                        return @end('errored')

                # capture topic
                @on 'topic', () =>
                    if @hasTopic
                        args = Array.prototype.slice.call(arguments)
                        @topics = args.concat(@topics)
                
                # setup the next level
                @hasTests = false
                for key, child of @content
                    do (child) =>
                        @results.running++
                        
                        # report the context of the tests
                        if not @hasTests and child.type == 'test'
                            @hasTests = true
                            @on 'run', () =>
                                context = this
                                parts = [@description]
                                while (context = context.parent) and context.parent != vows.runner
                                    parts.unshift(context.description) if context.description
                                
                                @report 'context', 
                                    description: parts.join(' ')
                    
                        @on 'topic', () =>
                            if child.type == 'test' and @_errorPattern.test(child.content)
                                child.run([null].concat(@topics))
                            else
                                child.run(@topics)
                            
                        @on 'error', (e) =>
                            if child.type == 'test' and @_errorPattern.test(child.content)
                                child.run(arguments)
                            else
                                # unexpected error
                                child.exception = e
                                child.end('errored')

                        child.on 'end', (result) =>
                            # end if this was the last test of the group
                            @end('done') if not --@results.running

                # teardown
                @on 'topic', () => @teardown.apply(this, @topics) if @teardown?

                # get the topic and run the test
                if not @topic?
                    if @topics.length
                        @topic = @topics[0]

                else if typeof @topic == 'function'
                    try
                        @topic = @topic.apply(@env, @topics)
                        if not @topic?
                            @async = true
                        else if @async
                            @topic = null
                            
                    catch e
                        @error(e)
                        return this

                if @topic?
                    if @topic instanceof events.EventEmitter
                        @async = true
                        @topic.on 'success', () => @success.apply(this, arguments)
                        @topic.on 'error', () => @error.apply(this, arguments)
                    else
                        @async = false
                        @success(@topic)
                
                else if not @async
                    # Groups with no topic
                    @success()
                
        return this

    end: (result) ->
        if @status in ['end']
            throw new vows.VowsError(this, 'The \'end\' event was triggered twice')
            
        @result = result
        @results.endDate = new Date
        @results.duration = (@results.endDate - @results.startDate) / 1000

        if @type == 'group'
            if @result == 'errored' and not @hasTests
                context = this
                parts = [@description]
                while (context = context.parent) and context.parent != vows.runner
                    parts.unshift(context.description) if context.description
                
                @report 'context',
                    description: parts.join(' ')
                    exception: @exception
                
        if @type in ['test', 'comment']
            @results[@result]++
            @report 'vow',
                description: @description
                content: @content
                context: @parent.description
                result: @result
                duration: @results.duration
                exception: @exception

        if @parent?
            for key in ['running', 'honored', 'pending', 'broken', 'errored']
                @parent.results[key] += @results[key]
        
        @emit(@status = 'end', @result)
        return this

    success: () ->
        args = Array.prototype.slice.call(arguments)
        args.unshift(null)
        @callback.apply(this, args)
        
    error: () ->
        args = Array.prototype.slice.call(arguments)
        args.unshift(new Error('Unspecified error')) if not args.length
        @callback.apply(this, args)
        
    callback: () =>
        if @status in ['run', 'end']
            if @async
                throw new vows.VowsError(this, 'An asynchronous callback was made after a value was returned.')
            else
                throw new vows.VowsError(this, 'An asynchronous callback was made twice.')

        @emit(@status = 'run')
        args = Array.prototype.slice.call(arguments)
        e = args.shift()
    
        # treat a single boolean as success
        if typeof e == 'boolean' and not args.length
            @emit('topic', e);
        else if e?
            @exception = e
            @emit.apply(this, ['error', e].concat(args))
        else
            @emit.apply(this, ['topic'].concat(args))
        
        # prevent CoffeeScript from returning a value
        return

    add: (context) ->
        switch @type
            when 'batch' then @content.push(context)
            when 'group' then @content[context.description] = context
            else throw new vows.VowsError(this, 'Can\'t add to tests or comments')

        context.parent = this
        @results.total += context.results.total
        
        return this

    # Compatibility with regular vows
    export: (module, options) ->
        return module.exports[@description] = this
            
    @::exportTo = @::export
    @::addBatch = @::add


class vows.Runner extends vows.Context
    _totalTests: () ->
        switch @type
            when 'group'
                groupTotal = 0

                for key, child of @content
                    groupTotal += @content[key].type == 'test'
                    
                return 

    run: (callback) ->
        @on 'end', () =>
            @results.dropped = @results.total - (@results.honored + @results.pending +
                                                 @results.errored + @results.broken)
                                                 
            @report('finish', @results)
            callback(@results) if callback?
            
        return super()

vows.runner = new vows.Runner(null, [])


#process.on 'exit', () -> debugger

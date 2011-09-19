vows.reporters = reporters = {}

vows.report = () -> vows.reporter.report.apply(vows.reporter, arguments) if vows.reporter

class reporters.BaseReporter
    name: 'silent'
    constructor: () -> @reset()
    reset: () -> null
    report: (data) -> null
    print: (ob) -> process.stdout.write('' + ob)
    stylize: (ob) -> vows.stylize(ob)


class reporters.JSONReporter extends reporters.BaseReporter
    name: 'json'
    report: () -> @print(JSON.stringify(Array.prototype.slice.call(arguments)) + '\n')


class reporters.SpecReporter extends reporters.BaseReporter
    name: 'spec'
    report: (name, event) ->
        switch name
            when 'subject' then @print("\n\n♢ #{@stylize(event).bold()}\n")
            when 'context' then @print(@_contextEvent(event))
            when 'vow' then @print(@_vowEvent(event))
            when 'end' then @print('\n')
            when 'finish' then @print('\n' + @_resultEvent(event))
            when 'error' then @print(@_errorEvent(event))

    _contextEvent: (event) ->
        if event.exception then @stylize("\n  #{event.description}\n").error()
        else "\n  #{event.description}\n"
        
    
    _vowEvent: (event) ->
        return switch event.result
            when 'honored' then @stylize("    ✓ #{event.description}\n").success()
            when 'broken'  then @stylize("    ✗ #{event.description}\n      » #{event.exception}\n").warning()
            when 'errored' then @stylize("    ⊘ #{event.description}\n      » #{event.exception}\n").error()
            when 'pending' then @stylize("    ∴ #{event.description}\n      » #{event.content}\n").pending()

    _resultEvent: (event) ->
        if event.total == 0
            return @stylize('Could not find any tests to run.\n').bold().error()

        status = (event.errored and 'errored') or (event.dropped and 'dropped') or
                 (event.broken and 'broken') or (event.honored and 'honored') or
                 (event.pending and 'pending')

        header = switch status
            when 'errored' then @stylize("⊘ #{@stylize('Errored').bold()}").error()
            when 'dropped' then @stylize("… #{@stylize('Incomplete').bold()}").error()
            when 'broken'  then @stylize("✗ #{@stylize('Broken').bold()}").warning()
            when 'honored' then @stylize("✓ #{@stylize('Honored').bold()}").success()
            when 'pending' then @stylize("∴ #{@stylize('Pending').bold()}").pending()

        message = []
        for key in ['honored', 'pending', 'broken', 'errored', 'dropped']
            message.push("#{@stylize(event[key]).bold()} #{key}") if event[key]

        time = @stylize(event.duration.toFixed(3)).message()
        return @stylize("#{header} » #{message.join(' ∙ ')} (#{time})\n").result()

    _errorEvent: (event) ->
        return ("✗ #{@stylize('Errored').error()} " + 
                "» #{@stylize(vow.description).bold()}" +
                ": #{@stylize(vow.exception).error()}\n")
                
                
class reporters.DotMatrixReporter extends reporters.SpecReporter
    name: 'dot-matrix'
    reset: () ->
        @messages = []
        @lastContext = null

    report: (name, event) ->
        switch name
            when 'subject' then null
            when 'context' then null
            when 'vow'
                switch event.result
                    when 'honored' then @print(@stylize('·').success())
                    when 'pending' then @print(@stylize('-').pending())
                    when 'broken', 'errored'
                        if @lastContext != event.context
                            @lastContext = event.context
                            @messages.push("  #{event.context}")

                        @print(@stylize('✗', if event.result == 'broken' then 'warning' else 'error'))
                        @messages.push(@_vowEvent(event))

            when 'end' then @print(' ')
            when 'finish'
                if @messages.length
                    @print('\n\n' + @messages.join('\n') + '\n')
                else
                    @print('\n')

                @print(@_resultEvent(event) + '\n')

            when 'error' then @print(@_errorEvent(event))


class reporters.HTMLSpecReporter extends reporters.SpecReporter
    name: 'html-spec'
    print: (ob) -> document.getElementById('vows-results').innerHTML += ob

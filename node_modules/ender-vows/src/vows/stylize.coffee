vows.stylizers = stylizers = {}

vows.stylize = (ob) ->
    s = new vows.stylizer(ob)
    for arg in Array.prototype.slice.call(arguments)[1..]
        s.stylize(arg)
        
    return s


vows.format = (str) -> 
    str = str.replace /`([^`]+)`/g, (_, part) => vows.stylize(part).italic()
    str = str.replace /\*([^*]+)\*/g, (_, part) => vows.stylize(part).bold()
    str = str.replace /_([^_]+)_/g, (_, str) => vows.stylize(part).underline()
    return str


_stack = []
vows.stringify = (obj) ->
    len = (obj) -> obj.length if 'length' of obj else Object.keys(obj).length 
    
    typeOf = (value) ->
        s = typeof value
        types = [Object, Array, String, RegExp, Number, Function, Boolean, Date]

        if s == 'object' or s == 'function'
            if value?
                for type in types
                    if value instanceof type
                        s = type.name.toLowerCase()

            else
                s = 'null'

        return s
    
    if obj in _stack
        before = _stack.length - _stack.indexOf(obj)
        return vows.stylize(('.' for i in [0..before]).join(''), 'special')
    
    _stack.push(obj)
    result = switch typeOf(obj)
        when 'regexp'    then vows.stylize('/' + obj.source + '/', 'regexp')
        when 'number'    then vows.stylize(obj.toString(), 'number')
        when 'boolean'   then vows.stylize(obj.toString(), 'boolean')
        when 'null'      then vows.stylize('null', 'special')
        when 'undefined' then vows.stylize('undefined', 'special')
        when 'function'  then vows.stylize('[Function]', 'other')
        when 'date'      then vows.stylize(obj.toUTCString(), 'default')
        when 'string'
            obj = if /'/.test(obj) then "\"#{obj}\"" else "'#{obj}'"
            obj = obj.replace(/\\/g, '\\\\')
                     .replace(/\n/g, '\\n')
                     .replace(/[\u0001-\u001F]/g, (match) -> '\\0' + match[0].charCodeAt(0).toString(8))
            vows.stylize(obj, 'string')
            
        when 'array'
            pretty = len(obj) > 4 or len(o for o in obj if len(o) > 0)
            
            start = if pretty then '\n' + (' ' for i in [0..4*_stack.length]).join('') else ' '
            end = if pretty then ws.slice(0, -4) else ' '
            sep = ",#{start}"
            
            contents = (vows.stringify(o) for o in obj).join(sep)
            if contents then "[#{start}#{contents}#{end}]" else '[]'

        when 'object'
            pretty = len(obj) > 2 or len(o for o in obj and len(o) > 0)

            start = if pretty then '\n' + (' ' for i in [0..4*_stack.length]).join('') else ' '
            end = if pretty then ws.slice(0, -4) else ' '
            sep = ",#{start}"
            
            contents = (vows.stylize(k).key() + ': ' + vows.stringify(v) for k, v of obj).join(sep)
            if contents then "{#{start}#{contents}#{end}}" else '{}'

    _stack.pop()
    return result


class stylizers.BaseStylizer
    constructor: (ob) -> @str = '' + ob
    toString: () -> @str


class stylizers.ConsoleStylizer extends stylizers.BaseStylizer
    styles: {
        plain     : null,
        bold      : [1,  22],
        light     : [2,  22], # not widely supported
        italic    : [3,  23], # not widely supported
        underline : [4,  24],
        negative  : [7,  27],
        concealed : [8,  28],
        struck    : [9,  29],

        black     : [30, 39],
        red       : [31, 39],
        green     : [32, 39],
        yellow    : [33, 39],
        blue      : [34, 39],
        magenta   : [35, 39],
        cyan      : [36, 39],
        white     : [37, 39],
        grey      : [90, 39],
    }

    mapping: {
        success  : 'green',
        error    : 'red',
        warning  : 'yellow',
        pending  : 'cyan',
        message  : 'grey',
        result   : 'plain',

        label    : 'underline',
        key      : 'bold',
        string   : 'green',
        number   : 'magenta',
        boolean  : 'blue',
        special  : 'grey',
        regexp   : 'green',
        function : 'negative',
        comment  : 'cyan',
    }

    for k, v of @::mapping
        @::styles[k] = @::styles[v]

    for style of @::styles
        do (style) =>
            @::[style] = () -> @stylize(style)

    stylize: (style) ->
        @str = "\033[#{@styles[style][0]}m#{@str}\033[#{@styles[style][1]}m" if @styles[style]
        return this


class stylizers.HTMLStylizer extends stylizers.BaseStylizer
    styles: {
        bold      : ['b', null],
        italic    : ['i', null],
        underline : ['u', null],
    }

    divs: [
        'success',
        'error',
        'warning',
        'pending',
        'result',
        'message',
    ]

    spans: [
        'label',
        'key',
        'string',
        'number',
        'boolean',
        'special',
        'regexp',
        'function',
        'comment',
    ]

    for c in @::divs
        @::styles[c] = ['div', c]

    for c in @::spans
        @::styles[c] = ['span', c]

    for style of @::styles
        do (style) =>
            @::[style] = () -> @stylize(style)

    stylize: (style) ->
        [tagName, className] = @styles[style]
        classAttr = if className then " class=\"#{className}\"" else ""
        @str = "<#{tagName}#{classAttr}>#{@str}</#{tagName}>"
        return this

!((wings) ->
    wings.renderTemplate = (template, data, links) ->
        # Replace escaped braces with an obscure unicode curly brace
        template = replaceBraces(template)
        template = renderRawTemplate(template, data, links)
        template = restoreBraces(template)
        return template


    replaceBraces = (template) -> template.replace(/\{\{/g, '\ufe5b').replace(/\}\}/g, '\ufe5d')
    restoreBraces = (template) -> template.replace(/\ufe5b/g, '{').replace(/\ufe5d/g, '}')
    
    isArray = Array.isArray ? ((o) -> Object.prototype.toString.call(o) == '[object Array]')
    
    escapeXML = (s) ->
        return (s or '').toString().replace /&(?!\w+;)|["<>]/g, (s) ->
            switch s 
                when '&' then return '&amp'
                when '"' then return '\"'
                when '<' then return '&lt'
                when '>' then return '&gt'
                else return s
    
    parse_re = ///
        \s* \{([!:]) \s* ([^}]*?) \s*\ } ([\S\s]+?) \s* \{/ \s* \2 \s*\} |     # sections
        \{([@&]?) \s* ([^}]*?) \s* \} |                                        # tags
        \{(\#) \s* [\S\s]+? \s* \#\}                                           # comments
    ///mg

    renderRawTemplate = (template, data, links) ->
        template.replace parse_re, (match, section_op, section_name, section_content, tag_op, tag_name, comment_op) ->
            op = section_op or tag_op or comment_op
            name = section_name or tag_name
            content = section_content

            switch op
                when ':' # section
                    value = data[name]
                    if not value?
                        throw "Invalid section: #{data}: #{name}: #{value}"
        
                    else if isArray(value)
                        return (renderRawTemplate(content, v, links) for v in value).join('')
        
                    else if typeof value == 'object'
                        return renderRawTemplate(content, value, links)

                    else if typeof value == 'function'
                        return value.call(data, content)

                    else if value
                        return renderRawTemplate(content, data, links)
                        
                    else
                        return ""
    
                when '!' # inverted section
                    value = data[name]
                    if not value?
                        throw "Invalid inverted section: #{data}: #{name}: #{value}"
                        
                    else if not value or (isArray(value) and value.length == 0)
                        return renderRawTemplate(content, data, links)
                        
                    else
                        return ""

                when '#' # comment tag
                    return ''

                when '@' # link tag
                    link = if links then links[name] else null
                
                    if not link?
                        throw "Invalid link: #{links}: #{name}: #{link}"
                        
                    else if typeof link == 'function'
                        link = link.call(data)

                    return renderRawTemplate(replaceBraces(link), data, links)

                when '&', '' # value tag
                    value = data
                    while value and name
                        [part, name] = name.match(/^([^.]*)\.?(.*)$/)[1..]
                        if part of value
                            value = value[part]
                        else
                            value = null
                    
                    if not value?
                        throw "Invalid value: #{data}: #{name}: #{value}"
                        
                    else if typeof value == 'function'
                        value = value.call(data)

                    return (if op == '&' then value else escapeXML(value))

)(exports ? (@['wings'] = {}))
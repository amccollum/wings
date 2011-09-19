!(($) ->
    renderTemplate = require('wings').renderTemplate
    
    $.ender({renderTemplate: renderTemplate})
    $.ender({
        render: (data, links) -> renderTemplate(this[0].innerHTML, data, links)
    }, true)
)(ender)
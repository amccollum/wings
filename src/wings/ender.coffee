!(($) ->
    renderTemplate = require('wings').renderTemplate
    
    $.ender({renderTemplate: renderTemplate})
    $.ender({
        render: (data, links) -> renderTemplate(@html(), data, links)
    }, true)
)(ender)
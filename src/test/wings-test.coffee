assert = require('assert')
vows = require('vows')

t = require('wings').renderTemplate
equal = assert.equal

if not vows.add
    vows.add = (name, batch) -> vows.describe(name).addBatch(batch).export(module)

vows.add 'templates'
    'basics:':
        'an empty template':
            topic: t('')
            'should be equal to the empty string': (topic) ->
                equal topic, ''
    
        'a template with no tags':
            topic: t('I think, therefore I am.')
            'should be equal to the same string': (topic) ->
                equal topic, 'I think, therefore I am.'
        
        'templates with escaped braces':
            topic: [
                t('I think, {{therefore I am.}}'),
                t('I }}{{think, {{{{therefore I am.}}}}'),
                t('nested {{ {:truthy}{{ braces }} {{{/truthy} }}', {truthy: true}),
            ]
                
            'should have double braces replaced with single braces': (topics) ->
                equal topics[0], 'I think, {therefore I am.}'
                equal topics[1], 'I }{think, {{therefore I am.}}'
                equal topics[2], 'nested { { braces } { }'


    'tags:':
        'a template with a single tag':
            topic: t('{test}', {test: 'blah'})
            'should be equal to the tag value': (topic) ->
                equal topic, 'blah'

        'a template with multiple tags':
            topic: t('The {adj1}, {adj2} fox {verb1} over the {adj3} dogs.',
                     {adj1:'quick', adj2:'brown', adj3:'lazy', verb1:'jumped'})
        
            'should replace all the tags': (topic) ->
                equal topic, 'The quick, brown fox jumped over the lazy dogs.'
      

        'a template with dotted tags':
            topic: t('The {adjs.adj1}, {adjs.adj2} fox {verbs.verb1} over the {adjs.adj3} dogs.',
                     {adjs: {adj1:'quick', adj2:'brown', adj3:'lazy'}, verbs: {verb1:'jumped'}})
                        
            'should replace the tags with the object properties': (topic) ->
                equal topic, 'The quick, brown fox jumped over the lazy dogs.'
    
        'a template with a function tag':
            topic: t('The result of the function is: "{fn1}".', {fn1: -> 'test'})
        
            'should replace the tag with the result of the function': (topic) ->
                equal topic, 'The result of the function is: "test".'

        'a template with comment tags':
            topic: t('There are comments{# comment #} in this template{# longer comment #}.')
        
            'should remove the comments when rendered': (topic) ->
                equal topic, 'There are comments in this template.'

        'a template with escaped tags':
            topic: t('This shouldn\'t produce html: {html}', {html: '<b>bolded</b>'})
        
            'should escape the html reserved characters': (topic) ->
                equal topic, 'This shouldn\'t produce html: &lt;b&gt;bolded&lt;/b&gt;'

        'a template with unescaped tags':
            topic: t('This should produce html: {&html}', {html: '<b>bolded</b>'})
        
            'should produce html': (topic) ->
                equal topic, 'This should produce html: <b>bolded</b>'

        'a template with unescaped tags (whitespace in tag)':
            topic: [
                t('This should produce html: {& html }', {html: '<b>bolded</b>'}),
                t('This should produce html: {&  html}', {html: '<b>bolded</b>'}),
                t('This should produce html: {&html  }', {html: '<b>bolded</b>'}),
                t('This should produce html: {& \thtml \t\t}', {html: '<b>bolded</b>'}),
            ]

            'should produce html': (topics) ->
                equal topics[0], 'This should produce html: <b>bolded</b>'
                equal topics[1], 'This should produce html: <b>bolded</b>'
                equal topics[2], 'This should produce html: <b>bolded</b>'
                equal topics[3], 'This should produce html: <b>bolded</b>'

        'a template with tags having the value 0':
            topic: t('This is a zero: {zero}', {zero: 0})
        
            'should preserve the zero': (topic) ->
                equal topic, 'This is a zero: 0'


    'links:':
        'a template with a normal link':
            topic: t('{@foo}', {bar: 'baz'}, {foo:'{bar}'})
        
            'should follow the link': (topic) ->
                equal topic, 'baz' 

        'a template with a normal link (whitespace in tag)':
            topic: [
                t('{@ foo }', {bar: '1baz'}, {foo:'{ bar }'})
                t('{@  foo}', {bar: '2baz'}, {foo:'{bar   }'}),
                t('{@foo  }', {bar: '3baz'}, {foo:'{bar   }'}),
                t('{@ \tfoo\t\t}', {bar: '4baz'}, {foo:'{\tbar\t   }'}),
            ]

            'should produce html': (topics) ->
                equal topics[0], '1baz'
                equal topics[1], '2baz'
                equal topics[2], '3baz'
                equal topics[3], '4baz'

        'a template with a function link':
            topic: t('{@foo}', {bar: 'baz'}, {foo: () -> '{bar}'})
        
            'should call the function to get the link': (topic) ->
                equal topic, 'baz'


    'sections:':
        'templates with regular sections':
            topic: [
                t('{:falsy}foo{/falsy}bar', {falsy: 0}),
                t('{:falsy}foo{/falsy}bar', {falsy: []}),
                t('{:falsy}foo{/falsy}bar', {falsy: false}),
            
                t('{:truthy}foo{/truthy}bar', {truthy: 1}),
                t('{:truthy}foo{/truthy}bar', {truthy: {}}),
                t('{:truthy}foo{/truthy}bar', {truthy: true}),
            ]
    
            'should only include the section when the tag is truthy': (topics) ->
                equal topics[0], 'bar'
                equal topics[1], 'bar'
                equal topics[2], 'bar'
                equal topics[3], 'foobar'
                equal topics[4], 'foobar'
                equal topics[5], 'foobar'

        'templates with regular sections (whitespace in tags)':
            topic: [
                t('{:  falsy }foo{/falsy}1{:  truthy }bang{/truthy  }', {falsy: 0, truthy: 1}),
                t('{:  falsy}foo{/  falsy}2{:  truthy }bang{/truthy  }', {falsy: 0, truthy: 1}),
                t('{:falsy}foo{/ falsy }3{: truthy }bang{/  truthy  }', {falsy: 0, truthy: 1}),
                t('{:\tfalsy\t}foo{/falsy}4{:\ttruthy\t}bang{/\ttruthy\t}', {falsy: 0, truthy: 1})
            ]
        
            'should only include the section when the tag is truthy': (topics) ->
                equal topics[0], '1bang'
                equal topics[1], '2bang'
                equal topics[2], '3bang'
                equal topics[3], '4bang'

        'templates with inverse sections':
            topic: [
                t('{!falsy}foo{/falsy}bar', {falsy: 0}),
                t('{!falsy}foo{/falsy}bar', {falsy: []}),
                t('{!falsy}foo{/falsy}bar', {falsy: false}),
            
                t('{!truthy}foo{/truthy}bar', {truthy: 1}),
                t('{!truthy}foo{/truthy}bar', {truthy: {}}),
                t('{!truthy}foo{/truthy}bar', {truthy: true}),
            ]
        
            'should only include the section when the tag is not truthy': (topics) ->
                equal topics[0], 'foobar'
                equal topics[1], 'foobar'
                equal topics[2], 'foobar'
                equal topics[3], 'bar'
                equal topics[4], 'bar'
                equal topics[5], 'bar'

        'templates with inverse sections (whitespace in tags)':
            topic: [
                t('{!  falsy }foo{/falsy}1{!  truthy }bang{/truthy  }', {falsy: 0, truthy: 1}),
                t('{!  falsy}foo{/  falsy}2{!  truthy }bang{/truthy  }', {falsy: 0, truthy: 1}),
                t('{!falsy}foo{/ falsy }3{! truthy }bang{/  truthy  }', {falsy: 0, truthy: 1}),
                t('{!\tfalsy\t}foo{/falsy}4{!\ttruthy\t}bang{/\ttruthy\t}', {falsy: 0, truthy: 1})
            ]
        
            'should only include the section when the tag is not truthy': (topics) ->
                equal topics[0], 'foo1'
                equal topics[1], 'foo2'
                equal topics[2], 'foo3'
                equal topics[3], 'foo4'

        'templates with array sections':
            topic: [
                t('{:array}foo{/array}bar', {array: [1, 2, 3]}),
                t('{:array}{}{/array}', {array: ['foo', 'bar', 'baz']}),
                t('{:array}{}a{/array}', {array: [1, 2, 3, 4, 5]}),
                t('{:array}{name}{/array}', {array: [{name:'foo'}, {name:'bar'}, {name:'baz'}]}),
                t('{:array1}foo{/array1}bar{:array2}{}{/array2}{:array3}{}a{/array3}{:array4}{name}{/array4}', {
                    array1: [1, 2, 3],
                    array2: ['foo', 'bar', 'baz'],
                    array3: [1, 2, 3, 4, 5],
                    array4: [{name:'foo'}, {name:'bar'}, {name:'baz'}],
                }),
            ]
        
            'should render the section once for each item in the array': (topics) ->
                equal topics[0], 'foofoofoobar'
                equal topics[1], 'foobarbaz'
                equal topics[2], '1a2a3a4a5a'
                equal topics[3], 'foobarbaz' 
                equal topics[4], 'foofoofoobarfoobarbaz1a2a3a4a5afoobarbaz'

        'a template with an object section':
            topic: t('{:obj}{foo}{bar}{baz}{/obj}', {obj: {foo: '1', bar: '2', baz: '3'}})
        
            'should use the object as the new environment': (topic) ->
                equal topic, '123'

        'a template with a function section':
            topic: t('{:fn}abcdef{/fn}', {fn: (str) -> str.split('').reverse().join('')})
        
            'should replace the section with the result of the function': (topic) ->
                equal topic, 'fedcba'
            
        'a template with subtemplates':
            topic: t('{:tmpls}{name}: \'{text}\',{/tmpls}', {
                        tmpls: [
                            { name: 'tmpl1', text: 'The {adj1}, {adj2} fox {verb1} over the {adj3} dogs.' },
                            { name: 'tmpl2', text: '{:untrue}foo{/untrue}bar' },
                            { name: 'tmpl3', text: 'nested {{ {:truthy}{{ braces }} {{{/truthy} }}' },
                        ]})
                       
            'should insert the subtemplates unmodified': (topic) ->
                equal topic, '''tmpl1: 'The {adj1}, {adj2} fox {verb1} over the {adj3} dogs.',
                                tmpl2: '{:untrue}foo{/untrue}bar',
                                tmpl3: 'nested {{ {:truthy}{{ braces }} {{{/truthy} }}',
                             '''.replace(/\n/g, '')

        'templates with undefined sections':
            topic: [
                t('{:absent}foo{/absent}bar', {}),
                t('{!absent}foo{/absent}bar', {}),
                t('{:exists}foo{/exists}bar', {exists: true}),
                t('{!falsy}foo{/falsy}bar',   {falsy: false}),
            ]
    
            'should only include the section when the value is defined': (topics) ->
                equal topics[0], 'bar'
                equal topics[1], 'bar'
                equal topics[2], 'foobar'
                equal topics[3], 'foobar'

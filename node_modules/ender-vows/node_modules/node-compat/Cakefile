fs = require('fs')
sys = require('sys')
{spawn, exec} = require('child_process')

package = JSON.parse(fs.readFileSync('package.json', 'utf8'))

execCmds = (cmds) ->
    exec cmds.join(' && '), (err, stdout, stderr) ->
        output = (stdout + stderr).trim()
        console.log(output + '\n') if (output)
        throw err if err


task 'build', 'Run all build tasks', ->
    execCmds [
#        'cake build-test',
        'cake build-release',
    ]


#task 'build-test', 'Build the test folder', ->
#    execCmds [
#        'coffee --compile --bare --output ./test ./src/test/*.coffee',
#    ]


task 'build-release', 'Create a combined package of all sources', ->
    sources = [
        'src/node-compat/assert.coffee',
        'src/node-compat/events.coffee',
        'src/node-compat/require.coffee',
        'src/node-compat/streams.coffee',
        'src/node-compat/process.coffee',
    ].join(' ')
    
    execCmds [
        "coffee --compile --bare --join lib/node-compat.js #{sources}",
    ]

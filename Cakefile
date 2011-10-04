fs = require('fs')
sys = require('sys')
{spawn, exec} = require('child_process')

package = JSON.parse(fs.readFileSync('package.json', 'utf8'))

execCmds = (cmds) ->
    exec cmds.join(' && '), (err, stdout, stderr) ->
        output = (stdout + stderr).trim()
        console.log(output + '\n') if (output)
        throw err if err

task 'build', 'Build the library', ->
    execCmds [
        'coffee --bare --output ./lib ./src/wings/*.coffee',
    ]

task 'test', 'Build and run the test suite', ->
    execCmds [
        'cake build',
        'coffee --bare --output ./test ./src/test/*.coffee',
        'cp ./src/test/*.html ./test',
        'cp ./src/test/*.css ./test',
        'pushd test',
        'test -e ender.js || ender build ender-vows wings',
        'popd',
        'npm install --dev',
        'ln -sf ender-vows node_modules/vows',
        'node_modules/.bin/vows ./test/*-test.js'
    ]
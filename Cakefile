fs = require('fs')
{spawn, exec} = require('child_process')

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

        'coffee --compile --bare --output test src/test/*.coffee',
        'ln -sf ../src/test/index.html test',
        'ln -sf ../src/test/vows.css test',

        'npm install',
        'rm -f node_modules/wings node_modules/vows test/node_modules',
        'ln -sf ender-vows node_modules/vows',

        'cd test',
        'ln -sf ../node_modules node_modules',
        'ln -sf .. node_modules/wings',
        #'node_modules/.bin/ender build ender-vows ..',
        'node_modules/.bin/vows --spec *-test.js',
        'rm -f node_modules/wings node_modules/vows node_modules',
        'cd ..',
    ]
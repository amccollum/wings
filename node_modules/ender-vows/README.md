Vows-Coffee
====

> Asynchronous BDD in CoffeeScript running on the client and server

#### <http://vowsjs.org> #

introduction
---------------------------

This project is a reimplementation of Vows in CoffeeScript. Why do we care when Vows is already written in JavaScript? Well, first, because this rewrite runs in the browser, and rewriting Vows in CoffeeScript seemed easier than modifying the current version to remove all the dependencies on node. Second, the implementation is much cleaner in CoffeeScript, which allows for easier modification and extension.

Tests written for vows should run more or less unmodified, but there are a few API additions to make writing tests in CoffeeScript a little nicer.

example
-------

    vows = require('vows')
    assert = require('assert')

    class DeepThought
        question: (q) -> 42

    vows.add 'Deep Thought'
        'An instance of DeepThought':
            topic: new DeepThought

            'should know the answer to the ultimate question': (deepThought) ->
                assert.equal deepThought.question('what is the answer to the universe?'), 42
        
browser examples
----------------

Look in the /example folder to find examples of running vows in the browser.

differences from vows        
---------------------

There are some small differences from JavaScript _vows_:

    * only spec, dot-matrix, and json reporters
    * no --watch option for watching test files for changes
    * no automatic test discovery
    * no ability to reset tests and run them again
    * no per-suite reporters
    * no ability to report on tests that didn't finish

These things will be fixed as I have time to reimplement them in browser-compatible CoffeeScript.

documentation
-------------

Check out the vows documentation at <http://vowsjs.org>


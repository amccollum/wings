events = require('events')
streams = if provide? then provide('streams', {}) else (@streams = {})

class streams.ReadableStream extends events.EventEmitter
    readable: false
    setEncoding: () -> throw new Error('Not Implemented')
    pause: () -> throw new Error('Not Implemented')
    resume: () -> throw new Error('Not Implemented')
    destroy: () -> throw new Error('Not Implemented')


class streams.WriteableStream extends events.EventEmitter
    writeable: false
    write: (string) -> throw new Error('Not Implemented')
    end: (string) -> throw new Error('Not Implemented')
    destroy: () -> throw new Error('Not Implemented')


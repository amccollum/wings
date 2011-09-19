var assert, vows;
assert = require('assert');
vows = require('vows');
vows.add('Vows Result Types', {
  'When running tests on a topic,': {
    topic: function() {
      return true;
    },
    'a test that runs as expected is honored': function(topic) {
      return assert.equal(topic, true);
    },
    'a test that causes an assertion is broken': function(topic) {
      return assert.equal(topic, false);
    },
    'a test that throws an error reports as errored': function(topic) {
      throw new Error('The error that was thrown');
    },
    'a test that has a string value reports as pending': 'This test is pending.'
  },
  'If a terminal topic throws an error,': {
    topic: function() {
      throw new Error('The error thrown by the topic');
    },
    'all the children get the error,': function(topic) {
      return assert.equal(true, true);
    },
    'but it can be anticipated like a normal error': function(err) {
      return assert.equal(err.message, 'The error thrown by the topic');
    }
  },
  'If an intermediate topic throws an error,': {
    topic: function() {
      throw new Error('The error thrown by the topic');
    },
    'it will cause topics and tests below it to be dropped': {
      topic: function() {
        return 'this will never be run because the parent topic throws an error';
      },
      'a dropped test': function(topic) {
        return assert.equal(true, true);
      }
    }
  }
});
!(function($) {
  var ready, vows;
  vows = require('vows');
  ready = require('domready');
  return ready(function() {
    vows.run();
  });
})(ender);
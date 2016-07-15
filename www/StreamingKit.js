var exec = require('cordova/exec');

exports.play = function(url, success, error) {
  exec(success, error, "StreamingKit", "play", [url]);
};

exports.pause = function(success, error) {
  exec(success, error, "StreamingKit", "pause", []);
};

exports.resume = function(success, error) {
  exec(success, error, "StreamingKit", "resume", []);
};

exports.stop = function(success, error) {
  exec(success, error, "StreamingKit", "stop", []);
};

function dispatch(name, event) {
  var e = document.createEvent('HTMLEvents');
  e.streaming = event;
  e.initEvent('streamingKit:' + name, true, true, arguments);
  document.dispatchEvent(e);
}

exports.onStateChanged = function (event) {
  dispatch('state:changed', event);
}

exports.onError = function (event) {
  dispatch('error', event);
}

exports.READY = 0;
exports.RUNNING = 1;
exports.BUFFERING = 3;
exports.PAUSED = 3;
exports.STOPPED = 4;
exports.ERROR = 5;
exports.DISPOSED = 6;

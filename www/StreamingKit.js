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

exports.onStop = function (event) {
  dispatch('stop', event);
}

exports.state = {
  READY: 0,
  RUNNING: 1,
  PLAYING: 2,
  BUFFERING: 4,
  PAUSED: 8,
  STOPPED: 16,
  ERROR: 32,
  DISPOSED: 64
};

exports.stopReason = {
  None: 0,
  Eof: 1,
  UserAction: 2,
  PendingNext: 3,
  Disposed: 4,
  Error: 65535
};

exports.errorCode = {
  NONE: 0,
  DATA_SOURCE: 1,
  STREAM_PARSE_BYTES_FAILED: 2,
  AUDIO_SYSTEM_ERROR: 3,
  CODEC_ERROR: 4,
  DATA_NOT_FOUND: 5,
  OTHER: 65535
};

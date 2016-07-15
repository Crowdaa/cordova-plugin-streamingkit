var exec = require('cordova/exec');

exports.play = function(url, success, error) {
    exec(success, error, "CDVStreamingKitPlugin", "play", [url]);
};

exports.pause = function(success, error) {
    exec(success, error, "CDVStreamingKitPlugin", "pause", []);
};

exports.resume = function(success, error) {
    exec(success, error, "CDVStreamingKitPlugin", "resume", []);
};

exports.stop = function(success, error) {
    exec(success, error, "CDVStreamingKitPlugin", "stop", []);
};

function dispatch(name, event) {
  var e = document.createEvent('HTMLEvents');
  e.streaming = event;
  e.initEvent(name, true, true, arguments);
  document.dispatchEvent(e);
}

exports.onStateChanged = function (event) {
  dispatch('streaming-event', event);
}

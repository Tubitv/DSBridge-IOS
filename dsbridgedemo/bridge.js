(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? factory(exports) :
	typeof define === 'function' && define.amd ? define(['exports'], factory) :
	(factory((global.DSBridge = {})));
}(this, (function (exports) { 'use strict';

function log() {
  var _console;

  for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
    args[_key] = arguments[_key];
  }

  // eslint-disable-next-line no-console
  (_console = console).log.apply(_console, ['[bridge]'].concat(args));
}

var getBridge = function getBridge() {
  var options = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};

  var internalBridgeName = options.bridgeName || '_dsbridge';
  var internalBridge = window[internalBridgeName];
  if (!internalBridge) {
    throw new Error('No injected global bridge object.');
  }

  var counter = 0;
  var jsBridge = {
    callbackMap: {},
    handlerMap: {},
    errorHandlers: [],
    callHandler: function callHandler(name, args, callback) {
      if (typeof args === 'function') {
        callback = args;
        args = {};
      }
      if (typeof callback === 'function') {
        var callbackId = counter++;
        jsBridge.callbackMap[callbackId] = callback;
        // eslint-disable-next-line dot-notation
        args['_callbackId'] = callbackId;
      }
      args = JSON.stringify(args || {});
      log('callHandler', name, args);

      var ret = '';
      // WKWebview
      if (internalBridge.wk) {
        ret = prompt(internalBridgeName + '=' + name, args);
      } else {
        ret = internalBridge.callHandler(name, args);
      }

      return ret ? JSON.parse(ret).result : ret;
    },
    registerHandler: function registerHandler(name, handler) {
      jsBridge.handlerMap[name] = handler;
    },
    onError: function onError(handler) {
      jsBridge.errorHandlers.push(handler);
    },
    offError: function offError(handler) {
      if (handler) {
        jsBridge.errorHandlers.some(function (errorHandler, index) {
          if (errorHandler !== handler) return false;
          jsBridge.errorHandlers.splice(index, 1);
          return true;
        });
      } else {
        jsBridge.errorHandlers = [];
      }
    },
    init: function init() {
      log('init');
      if (internalBridge.wk) {
        prompt(internalBridgeName + 'init=');
      } else {
        internalBridge.init();
      }
    }
  };

  // extend internal bridge
  internalBridge.invokeHandler = function (name, args, callbackId) {
    var handler = jsBridge.handlerMap[name];
    var sendResponse = function sendResponse(result) {
      if (typeof callbackId !== 'number') return;
      log('invokeHandler sendResponse', name, args, callbackId, result);
      if (internalBridge.wk) {
        prompt(internalBridgeName + 'cid=' + callbackId, result);
      } else {
        internalBridge.returnValue(callbackId, result);
      }
    };

    if (handler.length === 2) {
      // async handler
      handler(args, function (response) {
        sendResponse(JSON.stringify(response));
      });
    } else {
      var response = {};
      try {
        response.result = handler(args);
      } catch (ex) {
        response.error = ex.toString();
      }
      sendResponse(JSON.stringify(response));
    }
  };
  internalBridge.invokeCallback = function (callbackId, result, complete) {
    log('invokeCallback', callbackId, result, complete);
    var callback = jsBridge.callbackMap[callbackId];
    if (complete) {
      delete jsBridge.callbackMap[callbackId];
    }
    callback(result);
  };

  return jsBridge;
};

exports.getBridge = getBridge;

Object.defineProperty(exports, '__esModule', { value: true });

})));

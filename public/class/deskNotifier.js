(function() {
  "use strict";
  var DeskNotifier, api, list, sync;

  api = window.webkitNotifications;

  /*
  The static class controls desktop notification
  */

  DeskNotifier = (function() {

    function DeskNotifier() {}

    DeskNotifier.list = [];

    /*
    	Ask for desktop notification permission.
    	onAnswer: (isEnabled)
    */

    DeskNotifier.askPermission = function(onAnswer) {
      if (!this.isSupported || this.isEnabled) return;
      return api.requestPermission(function() {
        if (typeof onAnswer === 'function') return onAnswer(this.isEnabled);
      });
    };

    /*
    	Pop out a notification
    	(parameterObj)
    	(content)
    	(title, content)
    	(iconPath, title, content, timeout, isClickToCancel)
    */

    DeskNotifier.notify = function(a, b, c, d, e) {
      var content, iconPath, isClickToCancel, timeout, title;
      if (!this.isSupported) return;
      if ((a != null) && typeof a === 'object') {
        iconPath = a.iconPath;
        title = a.title;
        content = a.content;
        timeout = a.timeout;
        isClickToCancel = a.isClickToCancel;
      } else {
        iconPath = '';
        isClickToCancel = e || true;
        if (!(b != null)) {
          content = a;
        } else if (!(c != null)) {
          title = a;
          content = b;
        } else {
          iconPath = a;
          title = b;
          content = c;
          timeout = d;
        }
      }
      iconPath = iconPath != null ? iconPath : '';
      title = title != null ? title : '';
      content = content != null ? content : '';
      isClickToCancel = isClickToCancel === true ? true || false : void 0;
      if (this.isEnabled) {
        return this._notify(iconPath, title, content, timeout, isClickToCancel);
      } else {
        return this.askPermission(function(isEnabled) {
          if (isEnabled) {
            return this._notify(iconPath, title, content, timeout, isClickToCancel);
          }
        });
      }
    };

    /*
    	Private, pop out a notification
    */

    DeskNotifier._notify = function(iconPath, title, content, timeout, isClickToCancel) {
      var notification;
      notification = api.createNotification(iconPath, title, content);
      this.list.push(notification);
      notification.addEventListener('close', function(e) {
        var index;
        index = DeskNotifier.list.indexOf(notification);
        if (index >= 0) return DeskNotifier.list.splice(index, 1);
      });
      notification.addEventListener('error', function(e) {
        var index;
        console.log('error', DeskNotifier.list);
        index = DeskNotifier.list.indexOf(notification);
        if (index >= 0) return DeskNotifier.list.splice(index, 1);
      });
      if (isClickToCancel) {
        notification.addEventListener('click', function() {
          return notification.cancel();
        });
      }
      if (typeof timeout === 'number' && timeout > 0) {
        setTimeout(function() {
          return notification.cancel();
        }, timeout);
      }
      return notification.show();
    };

    return DeskNotifier;

  })();

  /*
  Accessor Properties
  */

  Object.defineProperties(DeskNotifier, {
    /*
    	Whether the browser supports the feature.
    */
    isSupported: {
      get: function() {
        return api != null;
      }
    },
    /*
    	Whether the browser permits desktop notification.
    */
    isEnabled: {
      get: function() {
        return (api != null) && api.checkPermission() === 0;
      }
    }
  });

  /* Unit Test
  */

  window.DeskNotifier = DeskNotifier;

  list = [
    function() {
      return DeskNotifier.notify({
        iconPath: 'https://developer.mozilla.org/favicon.ico',
        title: 'Wait 5 seconds',
        content: 'Pass parameters as an object',
        timeout: 5000,
        isClickToCancel: false
      });
    }, function() {
      return DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'title', '3s', 3000);
    }, function() {
      return DeskNotifier.notify('click me');
    }, function() {
      return DeskNotifier.notify('title', 'click me');
    }, function() {
      return DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'title', 'click icon');
    }
  ];

  sync = function(list, timeout) {
    var func;
    if (func = list.shift()) {
      func();
      if (list.length > 0) {
        return setTimeout(function() {
          return sync(list, timeout);
        }, timeout);
      }
    }
  };

  sync(list, 500);

}).call(this);

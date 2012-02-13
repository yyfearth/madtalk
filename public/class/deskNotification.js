(function() {
  var DeskNotification, list, sync;

  DeskNotification = (function() {

    function DeskNotification() {}

    DeskNotification.isSupported = function() {
      return window.webkitNotifications != null;
    };

    DeskNotification.isEnabled = function() {
      return this.isSupported() && window.webkitNotifications.checkPermission() === 0;
    };

    DeskNotification.askPermission = function(callback) {
      if (this.isSupported() === false) return;
      return window.webkitNotifications.requestPermission(function() {
        if (typeof callback === 'function') return callback(this.isEnabled());
      });
    };

    DeskNotification.notify = function(iconPath, title, content, timeout, isClickToCancel) {
      if (this.isSupported() === false) return;
      if (this.isEnabled()) {
        return this._notify(iconPath, title, content, timeout, isClickToCancel);
      } else {
        return this.askPermission(function(isEnabled) {
          if (isEnabled) {
            return this._notify(iconPath, title, content, timeout, isClickToCancel);
          }
        });
      }
    };

    DeskNotification._notify = function(iconPath, title, content, timeout, isClickToCancel) {
      var notification;
      if (iconPath == null) iconPath = '';
      if (title == null) title = '';
      if (content == null) content = '';
      if (isClickToCancel == null) isClickToCancel = true;
      if (window.webkitNotifications.checkPermission() === 0) {
        notification = window.webkitNotifications.createNotification(iconPath, title, content);
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
      }
    };

    return DeskNotification;

  })();

  /* Unit Test
  */

  window.DeskNotification = DeskNotification;

  list = [
    function() {
      return DeskNotification.notify('https://developer.mozilla.org/favicon.ico', 'Should have icon', 1, 3000, true);
    }, function() {
      return DeskNotification.notify(null, 'No icon', 2, 3000, true);
    }, function() {
      return DeskNotification.notify(void 0, 'No icon', 3, 3000, true);
    }, function() {
      return DeskNotification.notify('', null, '4. no title', 3000, true);
    }, function() {
      return DeskNotification.notify('', void 0, '5. no title', 3000, true);
    }, function() {
      return DeskNotification.notify('', 'No timeout, click me', 6, null, true);
    }, function() {
      return DeskNotification.notify('', 'No timeout, click me', 7, void 0, true);
    }, function() {
      return DeskNotification.notify('', 'no timeout, click me', 8, true, true);
    }, function() {
      return DeskNotification.notify('', 'Click is useless and no timeout', 9, false, false);
    }, function() {
      return DeskNotification.notify('', 'Click is useless', 10, 5000, false);
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

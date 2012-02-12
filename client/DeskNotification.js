(function() {
  var DeskNotification, list, sync;

  DeskNotification = (function() {

    function DeskNotification() {}

    return DeskNotification;

  })();

  DeskNotification.timeoutId = null;

  DeskNotification.isEnalbed = function() {
    return DeskNotification.isSupported() && webkitNotifications.checkPermission() === 0;
  };

  DeskNotification.isSupported = function() {
    return typeof webkitNotifications !== "undefined" && webkitNotifications !== null;
  };

  DeskNotification.askPermission = function(callback) {
    if (DeskNotification.isSupported() === false) return;
    return webkitNotifications.requestPermission(function() {
      if (typeof callback === 'function') {
        return callback(DeskNotification.isEnalbed());
      }
    });
  };

  DeskNotification.notify = function(iconPath, title, content, timeout, isClickToCancel) {
    if (DeskNotification.isSupported() === false) return;
    if (DeskNotification.isEnalbed()) {
      return DeskNotification._notify(iconPath, title, content, timeout, isClickToCancel);
    } else {
      return DeskNotification.askPermission(function(isEnalbed) {
        if (isEnalbed) {
          return DeskNotification._notify(iconPath, title, content, timeout, isClickToCancel);
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
    if (webkitNotifications.checkPermission() === 0) {
      notification = webkitNotifications.createNotification(iconPath, title, content);
      if (isClickToCancel) {
        notification.addEventListener('click', function() {
          return notification.cancel();
        });
      }
      if (typeof timeout === 'number' && timeout > 0) {
        DeskNotification.timeoutId = setTimeout(function() {
          return notification.cancel();
        }, timeout);
      }
      return notification.show();
    }
  };

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
      return DeskNotification.notify('', 'no timeotu, click me', 8, true, true);
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

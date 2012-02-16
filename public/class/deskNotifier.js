(function() {
  var DeskNotifier, api, list, sync;

  api = window.webkitNotifications;

  DeskNotifier = (function() {

    function DeskNotifier() {}

    DeskNotifier.list = [];

    DeskNotifier.askPermission = function(callback) {
      if (!this.isSupported || this.isEnabled) return;
      return api.requestPermission(function() {
        if (typeof callback === 'function') return callback(this.isEnabled);
      });
    };

    DeskNotifier.notify = function(iconPath, title, content, timeout, isClickToCancel) {
      if (!this.isSupported) return;
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

    DeskNotifier._notify = function(iconPath, title, content, timeout, isClickToCancel) {
      var notification;
      if (iconPath == null) iconPath = '';
      if (title == null) title = '';
      if (content == null) content = '';
      if (isClickToCancel == null) isClickToCancel = true;
      if (this.isEnabled) {
        notification = api.createNotification(iconPath, title, content);
        this.list.push(notification);
        /* Debug
        			notification.content = content
        			console.log "#{content} in"
        			notification.addEventListener('close', (e) ->
        				console.log DeskNotifier.list
        				console.log "#{this.content} out"
        				index = DeskNotifier.list.indexOf(notification)
        
        				if index >= 0
        					DeskNotifier.list.splice(index, 1)
        			)
        */
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
      }
    };

    return DeskNotifier;

  })();

  Object.defineProperties(DeskNotifier, {
    isSupported: {
      get: function() {
        return api != null;
      }
    },
    isEnabled: {
      get: function() {
        return (api != null) && api.checkPermission() === 0;
      }
    }
  });

  /* Unit Test
  */

  console.log(DeskNotifier.isSupported);

  console.log(DeskNotifier.isEnabled);

  window.DeskNotifier = DeskNotifier;

  list = [
    function() {
      return DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'Should have icon', 1, 3000, true);
    }, function() {
      return DeskNotifier.notify(null, 'No icon', 2, 3000, true);
    }, function() {
      return DeskNotifier.notify(void 0, 'No icon', 3, 3000, true);
    }, function() {
      return DeskNotifier.notify('', null, '4. no title', 3000, true);
    }, function() {
      return DeskNotifier.notify('', void 0, '5. no title', 3000, true);
    }, function() {
      return DeskNotifier.notify('', 'No timeout, click me', 6, null, true);
    }, function() {
      return DeskNotifier.notify('', 'No timeout, click me', 7, void 0, true);
    }, function() {
      return DeskNotifier.notify('', 'no timeout, click me', 8, true, true);
    }, function() {
      return DeskNotifier.notify('', 'Click is useless and no timeout', 9, false, false);
    }, function() {
      return DeskNotifier.notify('', 'Click is useless', 10, 5000, false);
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

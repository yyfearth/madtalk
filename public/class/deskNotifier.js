(function() {
  "use strict";
  var DeskNotifier, api, list, sync;

  api = window.webkitNotifications;

  /*
  The static class controls desktop notification.
  Only supports Chrome and cannot be used on local file system.
  */

  DeskNotifier = (function() {

    function DeskNotifier() {}

    DeskNotifier.list = [];

    /*
    	Ask for desktop notification permission.
    	@para onAnswered:function callback when answered.
    		@para isEnabled:boolean whether the permission is granted
    	@return object this object
    */

    DeskNotifier.askPermission = function(onAnswered) {
      if (!this.isSupported || this.isEnabled) return this;
      api.requestPermission(function() {
        if (typeof onAnswer === 'function') onAnswer(this.isEnabled);
      });
      return this;
    };

    /*
    	Pop out a notification
    	[
    		@para a:string the content
    	]
    	[
    		@para a:string the title
    		@para b:string the content
    	]
    	[
    		@para a:string the icon URI
    		@para b:string the title
    		@para c:string the content
    		@para d:number the time to close notification automatically
    		@para e:boolean default true, whether the notification is allowed to be closed by mouse click
    	]
    	@return object this object
    */

    DeskNotifier.notify = function(a, b, c, d, e) {
      var content, iconPath, isClickToClose, timeout, title;
      if (!this.isSupported) return this;
      if ((a != null) && typeof a === 'object') {
        iconPath = a.iconPath;
        title = a.title;
        content = a.content;
        timeout = a.timeout;
        isClickToClose = a.isClickToClose;
      } else {
        iconPath = '';
        isClickToClose = e || true;
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
      isClickToClose = isClickToClose === true ? true || false : void 0;
      if (this.isEnabled) {
        this._notify(iconPath, title, content, timeout, isClickToClose);
      } else {
        this.askPermission(function(isEnabled) {
          if (isEnabled) {
            return this._notify(iconPath, title, content, timeout, isClickToClose);
          }
        });
      }
      return this;
    };

    /*
    	Pop out a notification.
    */

    DeskNotifier._notify = function(iconPath, title, content, timeout, isClickToClose) {
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
      if (isClickToClose) {
        notification.addEventListener('click', function() {
          return notification.cancel();
        });
      }
      if (typeof timeout === 'number' && timeout > 0) {
        setTimeout(function() {
          return notification.cancel();
        }, timeout);
      }
      notification.show();
      return this;
    };

    return DeskNotifier;

  })();

  /*
  Accessor Properties
  */

  Object.defineProperties(DeskNotifier, {
    /*
    	@return boolean whether the browser supports the feature
    */
    isSupported: {
      get: function() {
        return api != null;
      }
    },
    /*
    	@return boolean whether the browser permits desktop notification
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
        isClickToClose: false
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
        setTimeout(function() {
          return sync(list, timeout);
        }, timeout);
      }
    }
    return this;
  };

  sync(list, 500);

}).call(this);

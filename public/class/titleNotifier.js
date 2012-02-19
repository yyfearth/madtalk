(function() {
  "use strict";
  /*
  A notifier makes the title blinking.
  */
  var NEW_TITLE, OLD_TITLE, TitleNotifier, blink, intervalId, isStarted, newTitle, oldTitle, status, target;

  TitleNotifier = (function() {

    function TitleNotifier() {}

    return TitleNotifier;

  })();

  /* Private
  */

  isStarted = false;

  oldTitle = '';

  newTitle = '';

  intervalId = null;

  NEW_TITLE = false;

  OLD_TITLE = true;

  status = OLD_TITLE;

  blink = function() {
    document.title = status === OLD_TITLE ? newTitle : oldTitle;
    status = !status;
  };

  /* Public
  */

  Object.defineProperties(TitleNotifier, {
    isStarted: {
      get: function() {
        return isStarted;
      },
      set: function() {
        if (isStarted) {
          return stop();
        } else {
          return start();
        }
      }
    },
    /*
    	Start blinking.
    	@para title:string the blinking title
    	@return object this object
    */
    start: {
      value: function(title, timeout) {
        if (isStarted) return this;
        newTitle = title;
        oldTitle = document.title;
        blink();
        intervalId = setInterval(function() {
          return blink();
        }, timeout);
        isStarted = true;
        return this;
      }
    },
    /*
    	Stop blinking.
    	@return object this object
    */
    stop: {
      value: function() {
        if (!isStarted) return this;
        clearInterval(intervalId);
        document.title = oldTitle;
        status = OLD_TITLE;
        isStarted = false;
        return this;
      }
    }
  });

  /* Unit Test
  */

  console.log('Debug script loaded at ' + (new Date()).toISOString());

  console.log(navigator.userAgent);

  target = window.TitleNotifier = TitleNotifier;

  document.addEventListener('DOMContentLoaded', function() {
    document.querySelector('#start').addEventListener('click', function() {
      return target.start('Hello world', 1000);
    });
    return document.querySelector('#stop').addEventListener('click', function() {
      return target.stop();
    });
  });

}).call(this);

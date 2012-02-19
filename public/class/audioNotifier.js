(function() {
  'use strict';
  /*
  Static class to play sound effects.
  */
  var AudioNotifier;

  AudioNotifier = (function() {

    function AudioNotifier() {}

    /*
    	A list of availible tracks, which is related to the real filepath.
    */

    AudioNotifier.listMusic = ['friendly.mp3', 'little.mp3', 'major.mp3'];

    /*
    	Play a sound. If the previous sound is not finished, they will be played together.
    	[
    		@para numOrName:number the number of track to play
    	]
    	[
    		@para numOrName:string the file name to play without extension
    	]
    	@return object this object
    */

    AudioNotifier.play = function(numOrName) {
      var src;
      if (typeof numOrName === 'number') {
        src = this.listMusic[numOrName];
      } else if (typeof numOrName === 'string') {
        src = numOrName + '.mp3';
      } else {
        src = this.listMusic[0];
      }
      (new Audio(src)).play();
      return this;
    };

    return AudioNotifier;

  })();

  /* Unit test
  */

  $(function() {
    var list, sync;
    window.audioNotifier = AudioNotifier;
    list = [
      [
        function() {
          return AudioNotifier.play(1);
        }, 1000
      ], [
        function() {
          return AudioNotifier.play('major');
        }, 1000
      ], [
        function() {
          return AudioNotifier.play();
        }, 1000
      ], [
        function() {
          return AudioNotifier.play(124124);
        }, 0
      ], [
        function() {
          return AudioNotifier.play('Hello world');
        }, 0
      ]
    ];
    sync = function(list) {
      var item;
      if (item = list.shift()) {
        item[0]();
        if (list.length > 0) {
          return setTimeout(function() {
            return sync(list);
          }, item[1]);
        }
      }
    };
    sync(list);
    return console.log("Expect to see two errors below.");
  });

}).call(this);

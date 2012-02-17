
/*
Static class to play sound effects.
*/

(function() {
  var AudioNotifier;

  AudioNotifier = (function() {

    function AudioNotifier() {}

    AudioNotifier.listMusic = ['friendly.mp3', 'little.mp3', 'major.mp3'];

    /*
    	Play a sound.
    	numOrName: the track number or the name.
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
      return (new Audio(src)).play();
    };

    return AudioNotifier;

  })();

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

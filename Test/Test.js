(function() {

  window.A = (function() {

    function A() {}

    return A;

  })();

  A.test = function(a, b, c) {
    this.a = a != null ? a : 1;
    this.b = b != null ? b : 2;
    this.c = c != null ? c : 3;
    console.log(this.a);
    console.log(b);
    return console.log(c);
  };

  A.test();

}).call(this);

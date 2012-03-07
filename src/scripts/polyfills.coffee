
unless Function::bind?
  Function::bind = (oThis) ->
    # closest thing possible to the ECMAScript 5 internal IsCallable function  
    if typeof @ isnt 'function'
      throw new TypeError 'Function.prototype.bind - what is trying to be bound is not callable'
   
    aArgs = Array::slice.call(arguments, 1)
    fToBind = @
    fNOP = -> ;
    fBound = ->
      fToBind.apply (if @ instanceof fNOP then @ else oThis or window),  
        (aArgs.concat Array.prototype.slice.call arguments)

    fNOP.prototype = @prototype;  
    fBound.prototype = new fNOP();  
  
    fBound;  

Date::getShortTimeString = (h24 = yes) ->
  h = @getHours()
  ampm = if h24 then '' else (if h < 12 then ' AM' else ' PM')
  h = h % 12 unless h24
  h = (if h > 9 then '' else '0') + h
  m = @getMinutes()
  m = (if m > 9 then '' else '0') + m
  s = @getSeconds()
  s = (if s > 9 then '' else '0') + s
  "#{h}:#{m}:#{s}#{ampm}"

###
Returns a description of this past date in relative terms.
Takes an optional parameter (default: 0) setting the threshold in ms which
is considered 'Just now'.

Examples, where new Date().toString() == 'Mon Nov 23 2009 17:36:51 GMT-0500 (EST)':

new Date().toRelativeTime()
--> 'Just now'

new Date('Nov 21, 2009').toRelativeTime()
--> '2 days ago'

// One second ago
new Date('Nov 23 2009 17:36:50 GMT-0500 (EST)').toRelativeTime()
--> '1 second ago'

// One second ago, now setting a now_threshold to 5 seconds
new Date('Nov 23 2009 17:36:50 GMT-0500 (EST)').toRelativeTime(5000)
--> 'Just now'
###

Date::toRelativeTime = (now_threshold) ->
  delta = new Date() - this
  now_threshold = parseInt now_threshold, 10
  now_threshold = 0 if isNaN now_threshold
  return 'Just now' if delta <= now_threshold
  units = null
  conversions =
    millisecond: 1 #  ms -> ms
    second: 1000 #  ms -> sec
    minute: 60 #  sec -> min
    hour: 60 #  min -> hour
    day: 24 #  hour -> day
    month: 30 #  day -> month (roughly)
    year: 12 #  month -> year

  for key of conversions
    break if delta < conversions[key]
    units = key # keeps track of the selected key over the iteration
    delta = delta / conversions[key]
  # pluralize a unit when the difference is greater than 1.
  delta = Math.floor delta
  units += 's' if delta isnt 1
  [ delta, units, 'ago' ].join ' '

Date.fromString = (str) -> new Date Date.parse str.replace /-/g, '/'

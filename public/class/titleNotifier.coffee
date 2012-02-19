"use strict"

###
A notifier makes the title blinking.
###
class TitleNotifier

### Private ###
isStarted = false
oldTitle = ''
newTitle = ''
intervalId = null

NEW_TITLE = false
OLD_TITLE = true
status = OLD_TITLE

blink = ->
	document.title = if status is OLD_TITLE then newTitle else oldTitle
	status = not status

### Public ###
Object.defineProperties TitleNotifier, {
	isStarted:
		get: ->
			return isStarted
		set: ->
			return if isStarted then stop() else start()

	###
	Start blinking.
	@para title:string the blinking title
	@return object this object
	###
	start:
		value: (title, timeout) ->
			if isStarted
				return @

			newTitle = title
			oldTitle = document.title

			blink()
			intervalId = setInterval ->
				blink()
			, timeout

			isStarted = true

			return @

	###
	Stop blinking.
	@return object this object
	###
	stop:
		value: ->
			if not isStarted
				return @
			
			clearInterval intervalId
			document.title = oldTitle
			status = OLD_TITLE
			isStarted = false

			return @
}

### Unit Test ###
console.log 'Debug script loaded at ' + (new Date()).toISOString()
console.log navigator.userAgent

target = window.TitleNotifier = TitleNotifier

document.addEventListener 'DOMContentLoaded', ->
	document.querySelector('#start').addEventListener 'click', ->
		target.start 'Hello world', 1000

	document.querySelector('#stop').addEventListener 'click', ->
		target.stop()
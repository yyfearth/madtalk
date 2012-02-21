'use strict'

###
Static class to play sound effects.
###
class AudioNotifier
	###
	A list of availible tracks, which is related to the real filepath.
	###
	@listMusic: [
		'friendly.mp3'
		'little.mp3'
		'major.mp3'
	]

	###
	Play a sound. If the previous sound is not finished, they will be played together.
	[
		@para numOrName:number the number of track to play
	]
	[
		@para numOrName:string the file name to play without extension
	]
	@return object this object
	###
	@play = (numOrName) ->
		if typeof numOrName is 'number'
			src = @listMusic[numOrName]
		else if typeof numOrName is 'string'
			src = numOrName + '.mp3'
		else
			src = @listMusic[0]

		new Audio(src).play()
		@

### Unit test ###
$ ->
	window.audioNotifier = AudioNotifier

	list = [
		[
			-> AudioNotifier.play 1
			1000
		]
		[
			-> AudioNotifier.play 'major'
			1000
		]
		[
			-> AudioNotifier.play()
			1000
		]
		[
			-> AudioNotifier.play 124124
			0
		]
		[
			-> AudioNotifier.play 'Hello world'
			0
		]
	]

	do sync = (list) ->
		if item = list.shift()
			item[0]()
			if list.length > 0
				setTimeout ->
					sync list
				, item[1]

	console.log "Expect to see two errors below."

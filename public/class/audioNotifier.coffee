###
Static class to play sound effects.
###
class AudioNotifier
	@listMusic: [
		'friendly.mp3'
		'little.mp3'
		'major.mp3'
	]

	###
	Play a sound.
	numOrName: the track number or the name.
	###
	@play = (numOrName) ->
		if typeof numOrName is 'number'
			src = @listMusic[numOrName]
		else if typeof numOrName is 'string'
			src = numOrName + '.mp3'
		else
			src = @listMusic[0]

		(new Audio(src)).play()

$ ->
	window.audioNotifier = AudioNotifier

	list = [
		[
			->
				AudioNotifier.play(1)
			1000
		]
		[
			->
				AudioNotifier.play('major')
			1000
		]
		[
			->
				AudioNotifier.play()
			1000
		]
		[
			->
				AudioNotifier.play(124124)
			0
		]
		[
			->
				AudioNotifier.play('Hello world')
			0
		]
	]

	sync = (list) ->
		if item = list.shift()
			item[0]()
			if list.length > 0
				setTimeout(->
					sync(list)
				, item[1])

	sync(list)

	console.log("Expect to see two errors below.")
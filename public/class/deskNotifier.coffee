api = window.webkitNotifications

# The static class controls desktop notification
class DeskNotifier
	@list: []
	# Ask for desktop notification permission.
	# callback: (isEnabled) ->
	@askPermission: (callback) ->
		if not @isSupported or @isEnabled
			return

		api.requestPermission(->
			if typeof callback is 'function'
				callback(@isEnabled)
			)

	# Used for notifying.
	@notify: (iconPath, title, content, timeout, isClickToCancel) ->
		if not @isSupported
			return

		if @isEnabled
			@_notify(iconPath, title, content, timeout, isClickToCancel)
		else
			@askPermission((isEnabled)->
				if isEnabled
					@_notify(iconPath, title, content, timeout, isClickToCancel)
			)

	# Used for notifying.
	@_notify: (iconPath = '', title = '', content = '', timeout, isClickToCancel = true) ->
		if @isEnabled
			notification = api.createNotification(iconPath, title, content)
			@list.push(notification)

			### TODO: check bug
			notification.content = content
			console.log "#{content} in"
			notification.addEventListener('close', (e) ->
				console.log DeskNotifier.list
				console.log "#{this.content} out"
				index = DeskNotifier.list.indexOf(notification)

				if index >= 0
					DeskNotifier.list.splice(index, 1)
			)
			###

			notification.addEventListener('error', (e) ->
				console.log 'error', DeskNotifier.list
				index = DeskNotifier.list.indexOf(notification)

				if index >= 0
					DeskNotifier.list.splice(index, 1)
			)

			if isClickToCancel
				notification.addEventListener('click', ->				
					notification.cancel()
				)
			
			if typeof timeout is 'number' and timeout > 0
				setTimeout(->
					notification.cancel()
				, timeout)

			notification.show()

# Accessor Properties
Object.defineProperties(DeskNotifier, {
	isSupported:
		get: ->
			return api?
	isEnabled:
		get: ->
			return api? and api.checkPermission() is 0
})

### Unit Test ###
console.log(DeskNotifier.isSupported)
console.log(DeskNotifier.isEnabled)

window.DeskNotifier = DeskNotifier

list = [
	-> DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'Should have icon', 1, 3000, true)
	-> DeskNotifier.notify(null, 'No icon', 2, 3000, true)
	-> DeskNotifier.notify(undefined, 'No icon', 3, 3000, true)
	-> DeskNotifier.notify('', null, '4. no title', 3000, true)
	-> DeskNotifier.notify('', undefined, '5. no title', 3000, true)
	-> DeskNotifier.notify('', 'No timeout, click me', 6, null, true)
	-> DeskNotifier.notify('', 'No timeout, click me', 7, undefined, true)
	-> DeskNotifier.notify('', 'no timeout, click me', 8, true, true)
	-> DeskNotifier.notify('', 'Click is useless and no timeout', 9, false, false)
	-> DeskNotifier.notify('', 'Click is useless', 10, 5000, false)
]

sync = (list,  timeout) ->
	if func = list.shift()
		func()
		if list.length > 0
			setTimeout(->
				sync(list, timeout)
			, timeout)

sync(list, 500)
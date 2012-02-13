# The static class controls desktop notification
class DeskNotification
	@isSupported: () ->
		return window.webkitNotifications?

	@isEnabled: () ->
		return @isSupported() and window.webkitNotifications.checkPermission() is 0

	# Public: ask for desktop notification permission.
	# callback: (isEnabled) ->
	@askPermission: (callback) ->
		if @isSupported() is false
			return

		window.webkitNotifications.requestPermission(->
			if typeof callback is 'function'
				callback(@isEnabled())
		)

	# Public: used for notifying.
	@notify: (iconPath, title, content, timeout, isClickToCancel) ->
		if @isSupported() is false
			return

		if @isEnabled()
			@_notify(iconPath, title, content, timeout, isClickToCancel)
		else
			@askPermission((isEnabled)->
				if isEnabled
					@_notify(iconPath, title, content, timeout, isClickToCancel)
			)

	# Private: used for notifying.
	@_notify: (iconPath = '', title = '', content = '', timeout, isClickToCancel = true) ->
		if window.webkitNotifications.checkPermission() is 0
			notification = window.webkitNotifications.createNotification(iconPath, title, content)

			if isClickToCancel
				notification.addEventListener('click', ->				
					notification.cancel()
				)
			
			if typeof timeout is 'number' and timeout > 0
				setTimeout(->
					notification.cancel()
				, timeout)

			notification.show()

### Unit Test ###
window.DeskNotification = DeskNotification

list = [
	-> DeskNotification.notify('https://developer.mozilla.org/favicon.ico', 'Should have icon', 1, 3000, true)
	-> DeskNotification.notify(null, 'No icon', 2, 3000, true)
	-> DeskNotification.notify(undefined, 'No icon', 3, 3000, true)
	-> DeskNotification.notify('', null, '4. no title', 3000, true)
	-> DeskNotification.notify('', undefined, '5. no title', 3000, true)
	-> DeskNotification.notify('', 'No timeout, click me', 6, null, true)
	-> DeskNotification.notify('', 'No timeout, click me', 7, undefined, true)
	-> DeskNotification.notify('', 'no timeout, click me', 8, true, true)
	-> DeskNotification.notify('', 'Click is useless and no timeout', 9, false, false)
	-> DeskNotification.notify('', 'Click is useless', 10, 5000, false)
]

sync = (list,  timeout) ->
	if func = list.shift()
		func()
		if list.length > 0
			setTimeout(->
				sync(list, timeout)
			, timeout)

sync(list, 500)
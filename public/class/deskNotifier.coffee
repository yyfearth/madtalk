"use strict"
api = window.webkitNotifications

###
The static class controls desktop notification
###
class DeskNotifier
	@list: []

	###
	Ask for desktop notification permission.
	onAnswer: (isEnabled)
	###
	@askPermission: (onAnswer) ->
		if not @isSupported or @isEnabled
			return

		api.requestPermission(->
			if typeof onAnswer is 'function'
				onAnswer(@isEnabled)
			)

	###
	Pop out a notification
	(parameterObj)
	(content)
	(title, content)
	(iconPath, title, content, timeout, isClickToCancel)
	###
	@notify: (a, b, c, d, e) ->
		if not @isSupported
			return

		if a? and typeof a is 'object'
			iconPath = a.iconPath
			title = a.title
			content = a.content
			timeout = a.timeout
			isClickToCancel = a.isClickToCancel
		else
			iconPath = ''
			isClickToCancel = e or true

			if not b?
				content = a
			else if not c?
				title = a
				content = b
			else
				iconPath = a
				title = b
				content = c
				timeout = d

		# Default value
		iconPath = iconPath ? ''
		title = title ? ''
		content = content ? ''
		isClickToCancel = if isClickToCancel is true then true or false

		if @isEnabled
			@_notify(iconPath, title, content, timeout, isClickToCancel)
		else
			@askPermission((isEnabled)->
				if isEnabled
					@_notify(iconPath, title, content, timeout, isClickToCancel)
			)

	###
	Private, pop out a notification
	###
	@_notify: (iconPath, title, content, timeout, isClickToCancel) ->
		notification = api.createNotification(iconPath, title, content)
		@list.push(notification)

		notification.addEventListener('close', (e) ->
			index = DeskNotifier.list.indexOf(notification)

			if index >= 0
				DeskNotifier.list.splice(index, 1)
		)

		notification.addEventListener('error', (e) ->
			console.log('error', DeskNotifier.list)
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

###
Accessor Properties
###
Object.defineProperties(DeskNotifier, {
	###
	Whether the browser supports the feature.
	###
	isSupported:
		get: ->
			return api?
	###
	Whether the browser permits desktop notification.
	###
	isEnabled:
		get: ->
			return api? and api.checkPermission() is 0
})

### Unit Test ###
window.DeskNotifier = DeskNotifier

list = [
	-> DeskNotifier.notify({
		iconPath: 'https://developer.mozilla.org/favicon.ico'
		title: 'Wait 5 seconds'
		content: 'Pass parameters as an object'
		timeout: 5000
		isClickToCancel: false
	})
	-> DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'title', '3s', 3000)
	-> DeskNotifier.notify('click me')
	-> DeskNotifier.notify('title', 'click me')
	-> DeskNotifier.notify('https://developer.mozilla.org/favicon.ico', 'title', 'click icon')
]

sync = (list,  timeout) ->
	if func = list.shift()
		func()
		if list.length > 0
			setTimeout(->
				sync(list, timeout)
			, timeout)

sync(list, 500)
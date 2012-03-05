Notifications = window.webkitNotifications

###
The static class controls desktop notification.
Only supports Chrome and cannot be used on local file system.
###
class DeskNotifier
	@list: []

	###
	Ask for desktop notification permission.
	@para onAnswered:function callback when answered.
		@para isEnabled:boolean whether the permission is granted
	@return object this object
	###
	@askPermission: (onAnswered) ->
		return @ if not @isSupported or @isEnabled

		Notifications.requestPermission ->
			onAnswered @isEnabled if typeof onAnswered is 'function'
			return
		@

	###
	Pop out a notification
	[
		@para a:string the content
	][
		@para a:string the title
		@para b:string the content
	][
		@para a:string the icon URI
		@para b:string the title
		@para c:string the content
		@para d:number the time to close notification automatically
		@para e:{boolean|function} default true, whether the notification is allowed to be closed by mouse click, if it is a function, it will be called after clicking
	]
	@return object this object
	###
	@notify: (a, b, c, d, e) ->
		return @ if not @isSupported

		if a? and typeof a is 'object'
			arg = a
		else
			arg =
				iconPath: ''
				click2Close: e or true

			if not b?
				arg.content = a
			else if not c?
				arg.title = a
				arg.content = b
			else
				arg.iconPath = a
				arg.title = b
				arg.content = c
				arg.timeout = d

		if @isEnabled
			@_notify arg
		else
			@askPermission (isEnabled) ->
				@_notify arg if isEnabled
		@

	###
	Pop out a notification.
	###
	@_notify: ({iconPath, title, content, timeout, click2Close}) ->
		throw 'content is necessary' unless content
		iconPath ?= ''
		title ?= @title or ''
		timeout = 0 unless timeout? > 0
		click2Close ?= off

		notification = Notifications.createNotification iconPath, title, content
		@list.push notification

		notification.addEventListener 'close', (e) ->
			index = DeskNotifier.list.indexOf notification
			DeskNotifier.list.splice index, 1 if index >= 0

		notification.addEventListener 'error', (e) ->
			console.log 'error', DeskNotifier.list
			index = DeskNotifier.list.indexOf notification

			DeskNotifier.list.splice index, 1 if index >= 0

		if click2Close
			notification.addEventListener 'click', ->				
				notification.cancel()
				click2Close() if typeof click2Close is 'function'
		
		if typeof timeout is 'number' and timeout > 0
			setTimeout ->
				notification.cancel()
			, timeout

		notification.show()
		@

###
Accessor Properties
###
Object.defineProperties DeskNotifier,
	###
	@return boolean whether the browser supports the feature
	###
	isSupported: get: -> Notifications?
	###
	@return boolean whether the browser permits desktop notification
	###
	isEnabled: get: -> Notifications? and Notifications.checkPermission() is 0


### Unit Test ###
# window.DeskNotifier = DeskNotifier

# list = [
# 	-> DeskNotifier.notify {
# 		iconPath: 'https://developer.mozilla.org/favicon.ico'
# 		title: 'Wait 5 seconds'
# 		content: 'Pass parameters as an object'
# 		timeout: 5000
# 		click2Close: false
# 	}
# 	-> DeskNotifier.notify 'https://developer.mozilla.org/favicon.ico', 'title', '3s', 3000
# 	-> DeskNotifier.notify 'click me'
# 	-> DeskNotifier.notify 'title', 'click me'
# 	-> DeskNotifier.notify 'https://developer.mozilla.org/favicon.ico', 'title', 'click icon'
# ]

# sync = (list,  timeout) ->
# 	if func = list.shift()
# 		func()
# 		if list.length > 0
# 			setTimeout ->
# 				sync list, timeout
# 			, timeout
# 	@

# sync list, 500

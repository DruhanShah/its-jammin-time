class_name MouseCapture
## Captures the mouse for first-person looking, in one place (player, pause menu, gargoyle quiz).
## Desktop always captures. Browsers only grant pointer lock with a fresh user gesture (a click or any
## key but Esc); without one `requestPointerLock()` is refused (and logs an error), e.g. after leaving a
## close-up with Esc or the computer's blackout auto-return. So on the web this only asks while the page
## has user activation, and the player retries on their next key or click (player.gd `_input`).


## Captures the mouse now if it can. `gesture`: called while handling the player's key/click (see
## `is_capture_gesture()`), so the browser will allow it. Returns true if it asked (on the web the lock
## lands a moment later).
static func capture(gesture := false) -> bool:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return true
	if not gesture and not can_capture_now():
		return false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	return true


## False only on the web while the page has no user activation (pointer lock would be refused).
static func can_capture_now() -> bool:
	if not OS.has_feature("web"):
		return true
	return bool(JavaScriptBridge.eval("!!(navigator.userActivation && navigator.userActivation.isActive)", true))


## True for input that is a user gesture a browser accepts for pointer lock and that isn't a pause key
## (Esc never grants activation, and Esc/P pause, which frees the mouse anyway).
static func is_capture_gesture(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return false
	return not (event.is_action_pressed("ui_cancel") or key.physical_keycode == KEY_P or key.keycode == KEY_ESCAPE)

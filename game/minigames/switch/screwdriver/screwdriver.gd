extends Node3D
## Switch game "screwdriver" (obstacle of the first blackout, see switch_games.gd): a close-up of the
## switchboard's cover, screwed shut. Rolling the keys around G anticlockwise (`TwistInput`)
## unscrews the current screw, `turns_per_screw` turns each; clockwise screws it back in. The gag:
## the last screw is a sticker. It peels off, the cover falls, and the story moves on to the
## restore game. Esc leaves (the screws are back in next time; only the whole cover counts).

const ID := &"screwdriver"

## Turns to unscrew one screw (one key step = 60°).
@export var turns_per_screw := 2.0
## Metres a screw backs out over its full unscrewing.
@export var back_out := 0.035
## Degrees the screwdriver scrapes over the sticker before it peels.
@export var sticker_degrees := 120.0
## How fast the screws and the screwdriver catch up with the keys (1/s).
@export var follow_speed := 14.0
## Seconds after the cover falls before moving on (longer while the narrator is still talking).
@export var exit_delay := 1.5
## Longest wait for the narrator's line before moving on anyway.
@export var max_line_wait := 10.0
@export var click_sound: AudioStream
@export var click_volume_db := -6.0
@export var drop_sound: AudioStream
@export var clatter_sound: AudioStream

var _turned: Array[float] = [] ## Degrees unscrewed, per screw.
var _shown: Array[float] = [] ## Degrees shown (eases toward `_turned`).
var _current := 0
var _moving := false ## The screwdriver is moving to the next screw (the keys still count).
var _done := false

@onready var _twist: TwistInput = $TwistInput
@onready var _cover: Node3D = $Cover
@onready var _screws: Array[Node] = $Cover/Screws.get_children()
@onready var _driver: Node3D = $Driver
@onready var _hint: TwistHint = $Hud/Hint
@onready var _count: Label = $Hud/Panel/Box/Count


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_turned.resize(_screws.size())
	_turned.fill(0.0)
	_shown = _turned.duplicate()
	_twist.twisted.connect(_on_twisted)
	_place_driver()
	_update_count()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _done:
		Transition.change_scene(Story.OFFICE)


func _process(delta: float) -> void:
	if _done:
		return
	var weight := 1.0 - exp(-follow_speed * delta)
	_shown[_current] = lerpf(_shown[_current], _turned[_current], weight)
	var screw: Node3D = _screws[_current]
	if not _is_sticker(_current):
		screw.rotation.z = deg_to_rad(_shown[_current])
		screw.position.z = back_out * _shown[_current] / _needed()
	if not _moving:
		_place_driver()
	_hint.progress = _turned[_current] / (sticker_degrees if _is_sticker(_current) else _needed())


func _on_twisted(delta: float) -> void:
	if _done:
		return
	var unscrew := -delta # Anticlockwise (negative) unscrews.
	var before := _turned[_current]
	var limit := sticker_degrees if _is_sticker(_current) else _needed()
	_turned[_current] = clampf(before + unscrew, 0.0, limit)
	if _turned[_current] == before:
		if unscrew < 0.0:
			Narrator.play(&"screwdriver_wrong_way") # Screwing in a screw that's already in.
		return
	Audio.play_sfx(click_sound, click_volume_db)
	if _turned[_current] >= limit:
		if _is_sticker(_current):
			_peel_sticker()
		else:
			_drop_screw()


func _needed() -> float:
	return turns_per_screw * 360.0


func _is_sticker(index: int) -> bool:
	return index == _screws.size() - 1


## The screwdriver's tip sits in the current screw's slot and turns with it.
func _place_driver() -> void:
	var screw: Node3D = _screws[_current]
	_driver.global_position = screw.global_position
	_driver.rotation.z = deg_to_rad(_shown[_current])


func _update_count() -> void:
	_count.text = "Screws: %d / %d" % [_current, _screws.size()]


## The unscrewed screw pops out and falls; the screwdriver moves on to the next one.
func _drop_screw() -> void:
	_moving = true
	var screw: Node3D = _screws[_current]
	var fall := create_tween().set_parallel()
	fall.tween_property(screw, "position:z", screw.position.z + 0.12, 0.5)
	fall.tween_property(screw, "position:y", screw.position.y - 1.2, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_property(screw, "rotation:x", randf_range(-6.0, 6.0), 0.5)
	fall.chain().tween_callback(screw.hide)
	get_tree().create_timer(0.35).timeout.connect(Audio.play_sfx.bind(drop_sound, -4.0))
	_current += 1
	_update_count()
	var next: Node3D = _screws[_current]
	var move := create_tween()
	move.tween_property(_driver, "position:z", _driver.position.z + 0.08, 0.15)
	move.tween_property(_driver, "global_position", next.global_position + Vector3(0, 0, 0.08), 0.35).set_trans(Tween.TRANS_SINE)
	move.tween_property(_driver, "global_position", next.global_position, 0.15)
	move.tween_callback(func() -> void: _moving = false)


## The last "screw" is a sticker of one: it flattens, peels off and flutters down; the cover falls.
func _peel_sticker() -> void:
	_done = true
	_hint.hide()
	var sticker: Node3D = _screws[_current]
	sticker.reparent(self) # So it keeps fluttering when the cover falls.
	_count.text = "Screws: %d / %d. Stickers: 1 / 1." % [_current, _current]
	Narrator.play(&"screwdriver_sticker")
	var peel := create_tween()
	peel.tween_property(sticker, "scale:z", 0.08, 0.2)
	peel.tween_property(sticker, "rotation:x", -0.5, 0.3)
	peel.tween_method(_flutter.bind(sticker, sticker.position), 0.0, 1.0, 2.6)
	peel.tween_callback(sticker.hide)
	var back := create_tween()
	back.tween_property(_driver, "position:z", _driver.position.z + 0.5, 0.6).set_delay(0.4).set_trans(Tween.TRANS_SINE)
	var fall := create_tween()
	fall.tween_interval(2.4)
	fall.tween_property(_cover, "rotation:x", deg_to_rad(95.0), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fall.tween_callback(Audio.play_sfx.bind(clatter_sound, -2.0))
	fall.tween_property(_cover, "position:y", _cover.position.y - 1.5, 0.35).set_ease(Tween.EASE_IN)
	fall.tween_interval(exit_delay)
	await fall.finished
	var waited := 0.0
	while Narrator.is_speaking() and waited < max_line_wait:
		await get_tree().create_timer(0.2).timeout
		waited += 0.2
	Story.switch_game_done(ID)
	Transition.change_scene(Story.next_switch_scene())


## A paper-thin sticker drifting down, swaying side to side (t = 0..1).
func _flutter(t: float, sticker: Node3D, from: Vector3) -> void:
	sticker.position = from + Vector3(sin(t * 8.0) * 0.07, -t * t * 0.55, 0.05 + t * 0.15)
	sticker.rotation.z = sin(t * 8.0 + 1.0) * 0.8

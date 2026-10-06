class_name Computer
extends Node2D
## The computer screen: "ComicWord 97 Lite", a cheap knock-off word processor (an AppWindow with a menu
## row, a toolbar with the font dropdown button and B/I/U toggles that do nothing, a ruler and a white
## page) that hosts minigames. Doesn't know about the office:
## enter with Computer.open() (or Transition.change_scene(SCENE), e.g. an Interactable's
## target_scene), leave with exit() (the Power button).
## The EventManager child decides when minigames start; this only hosts them.

signal minigame_started(id: StringName, minigame: Minigame)
signal minigame_completed(id: StringName)
signal minigame_failed(id: StringName)
signal buffer_changed
signal score_changed(score: int)

const SCENE := "res://minigames/computer/computer.tscn"
const FALLBACK_RETURN_SCENE := "res://world/office/office.tscn"
const CURSOR := "▌"
const FLICKER_SOUND := preload("res://assets/audio/sfx/freesound/spark_crackle_nachtmahr.wav")
const CRT_OFF_SOUND := preload("res://assets/audio/sfx/400_sounds_pack/power_down.wav")
const DEFAULT_DOCUMENT_FONT := preload("res://assets/fonts/ComicShannsMono-Regular.ttf")
## Space between the page's edge and the document text.
const PAGE_PADDING := Vector2(26, 18)
## Screen brightness steps before a blackout: [brightness, seconds held], like a dying fluorescent tube.
const BLACKOUT_FLICKER: Array[Vector2] = [
	Vector2(0.35, 0.06), Vector2(1.0, 0.1), Vector2(0.2, 0.05), Vector2(1.0, 0.3), Vector2(0.5, 0.05),
	Vector2(0.9, 0.08), Vector2(0.15, 0.07), Vector2(0.8, 0.12), Vector2(0.1, 0.05), Vector2(1.0, 0.14),
]

@export var registry: MinigameRegistry

## The document being typed. Minigames may read and rewrite it.
var buffer := "":
	set(value):
		buffer = value
		if is_node_ready():
			_refresh_editor()
		buffer_changed.emit()
## Text shown in the status bar before the word count (e.g. the ad storm's goal line). Minigames set it.
var status_note := "":
	set(value):
		status_note = value
		if is_node_ready():
			_refresh_status()

@onready var screen: Control = $Screen
@onready var editor: RichTextLabel = $Screen/Editor
@onready var status_bar: Label = $Screen/StatusBar
@onready var minigame_layer: Control = $Screen/MinigameLayer
## The toolbar's font box. The visit-1 font step (font_picker) opens its font list from it.
@onready var font_button: Button = %FontButton
@onready var page: Control = %Page

var _blacking_out := false


## Switches to the computer (with a fade), remembering where to come back to (defaults to the
## current scene). `minigames` (registry ids) are played one after another, see `queue()`;
## empty = free use with the EventManager's own list.
static func open(minigames: Array[StringName] = [], exit_when_done := true, return_scene := "") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	GameState.computer_return_scene = return_scene if return_scene else tree.current_scene.scene_file_path
	if minigames:
		queue(minigames, exit_when_done)
	Transition.change_scene(SCENE)


## Queues minigames for the next computer visit without going there (e.g. the story sets it, then the
## player walks to the desk and presses X). Listen to GameState.computer_minigame_finished /
## computer_queue_finished; with `exit_when_done` the computer returns to the office by itself.
static func queue(minigames: Array[StringName], exit_when_done := true) -> void:
	GameState.computer_queue = minigames.duplicate()
	GameState.computer_exit_when_done = exit_when_done


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ComicCursor.apply()
	tree_exiting.connect(ComicCursor.reset)
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	$Screen/PowerButton.pressed.connect(exit)
	page.item_rect_changed.connect(_fit_editor)
	_fit_editor.call_deferred()
	apply_document_font()
	_refresh_editor()


## Starts a registered minigame. `overrides` sets fields on its config copy (e.g. {"max_dodges": 5}).
## Returns null if the id is unknown or that minigame is already at its max_concurrent.
func start_minigame(id: StringName, overrides: Dictionary = {}) -> Minigame:
	var scene: PackedScene = registry.entries.get(id) if registry else null
	if not scene:
		push_error("Computer: no minigame registered as '%s'" % id)
		return null
	var minigame := scene.instantiate() as Minigame
	if not minigame:
		push_error("Computer: '%s' root doesn't extend Minigame" % id)
		return null
	if minigame.config:
		minigame.config = minigame.config.duplicate()
		for key in overrides:
			if key in minigame.config:
				minigame.config.set(key, overrides[key])
			else:
				push_warning("Computer: '%s' config has no field '%s'" % [id, key])
		var cap := minigame.config.max_concurrent
		if cap > 0 and active_minigames(id).size() >= cap:
			minigame.free()
			return null
	minigame.id = id
	minigame.computer = self
	minigame.completed.connect(minigame_completed.emit.bind(id))
	minigame.failed.connect(minigame_failed.emit.bind(id))
	minigame.request_spawn.connect(start_minigame)
	minigame_layer.add_child(minigame)
	minigame.begin()
	minigame_started.emit(id, minigame)
	return minigame


## Minigames currently on screen, optionally only those started as `id`.
func active_minigames(id := &"") -> Array[Minigame]:
	var found: Array[Minigame] = []
	for child in minigame_layer.get_children():
		var minigame := child as Minigame
		if minigame and not minigame.is_queued_for_deletion() and (id.is_empty() or minigame.id == id):
			found.append(minigame)
	return found


## Adds (or with a negative value, removes) points from the shared score shown in the status bar.
func add_score(points: int) -> void:
	GameState.score += points
	_refresh_status()
	score_changed.emit(GameState.score)


## Uses GameState.document_font for the document and shows its name in the font box (the visit-1 font
## step sets them).
func apply_document_font() -> void:
	var font: Font = load(GameState.document_font) if GameState.document_font else DEFAULT_DOCUMENT_FONT
	editor.add_theme_font_override(&"normal_font", font)
	font_button.text = (GameState.document_font_name if GameState.document_font_name else "Choose font...") + "    v"


## Removes every minigame without emitting completed/failed.
func stop_all() -> void:
	for minigame in active_minigames():
		minigame.cleanup()
		minigame.queue_free()


func exit() -> void:
	stop_all()
	var target := GameState.computer_return_scene if GameState.computer_return_scene else FALLBACK_RETURN_SCENE
	GameState.computer_return_scene = ""
	Transition.change_scene(target)


## Ends a visit with a power cut caused by the computer itself: the screen flickers, switches off like
## an old CRT (squashes to a white line, then a dot), the power goes out (`GameState.set_power(false)`)
## and the computer returns to the office, already dark. Story calls it when a visit's minigame queue is
## beaten; a minigame may also call it directly (e.g. the Eco Mode ad). Calling it again does nothing.
func blackout() -> void:
	if _blacking_out:
		return
	_blacking_out = true
	set_process_unhandled_key_input(false)
	$Screen/PowerButton.disabled = true
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.size = get_viewport_rect().size
	add_child(backdrop)
	move_child(backdrop, 0)
	var flash := ColorRect.new() # Also swallows clicks while the screen dies.
	flash.color = Color(1, 1, 1, 0)
	screen.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.pivot_offset = screen.size / 2.0
	Audio.play_sfx(FLICKER_SOUND, -6.0)
	var tween := create_tween()
	for step in BLACKOUT_FLICKER:
		tween.tween_property(screen, "modulate", Color(step.x, step.x, step.x), 0.02)
		tween.tween_interval(step.y)
	tween.tween_callback(Audio.play_sfx.bind(CRT_OFF_SOUND))
	tween.tween_property(flash, "color:a", 0.9, 0.06)
	tween.tween_property(screen, "scale:y", 0.005, 0.16).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(screen, "scale:x", 0.003, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(screen, "modulate:a", 0.0, 0.25)
	tween.tween_callback(GameState.set_power.bind(false))
	tween.tween_interval(0.8)
	tween.tween_callback(exit)


## Plain typing. Esc is deliberately not an exit.
func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key.pressed:
		return
	match key.keycode:
		KEY_BACKSPACE:
			buffer = buffer.left(-1)
		KEY_ENTER, KEY_KP_ENTER:
			buffer += "\n"
		KEY_TAB:
			buffer += "\t"
		_:
			if key.unicode < 32:
				return
			buffer += char(key.unicode)
	get_viewport().set_input_as_handled()


## A Control under a Node2D can't anchor to the viewport, so size the screen by hand.
func _fit_screen() -> void:
	screen.size = get_viewport_rect().size


## The editor stays a direct child of the screen (minigames place themselves over `editor.get_rect()`),
## laid over the page inside the word processor window.
func _fit_editor() -> void:
	var rect := page.get_global_rect()
	editor.position = rect.position - screen.global_position + PAGE_PADDING
	editor.size = rect.size - PAGE_PADDING * 2.0


func _refresh_editor() -> void:
	editor.text = buffer + CURSOR
	_refresh_status()


func _refresh_status() -> void:
	var words := buffer.replace("\n", " ").replace("\t", " ").split(" ", false).size()
	var note := status_note + "    " if status_note else ""
	status_bar.text = "Page 1 of 1    %s%d words    Score: %d" % [note, words, GameState.score]

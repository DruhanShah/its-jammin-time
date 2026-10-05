class_name Computer
extends Node2D
## The computer screen: a vim-ish editor that hosts minigames. Doesn't know about the office:
## enter with Computer.enter() (or change_scene_to_file(SCENE)), leave with exit().
## The EventManager child decides when minigames start; this only hosts them.

signal minigame_started(id: StringName, minigame: Minigame)
signal minigame_completed(id: StringName)
signal minigame_failed(id: StringName)
signal buffer_changed
signal score_changed(score: int)

const SCENE := "res://minigames/computer/computer.tscn"
const FALLBACK_RETURN_SCENE := "res://world/office/office.tscn"
const CURSOR := "▌"

@export var registry: MinigameRegistry

## The document being typed. Minigames may read and rewrite it.
var buffer := "":
	set(value):
		buffer = value
		if is_node_ready():
			_refresh_editor()
		buffer_changed.emit()

@onready var screen: Control = $Screen
@onready var editor: RichTextLabel = $Screen/Editor
@onready var status_bar: Label = $Screen/StatusBar
@onready var minigame_layer: Control = $Screen/MinigameLayer


## Switches to the computer, remembering where to come back to (defaults to the current scene).
static func enter(tree: SceneTree, return_scene := "") -> void:
	GameState.computer_return_scene = return_scene if return_scene else tree.current_scene.scene_file_path
	tree.change_scene_to_file(SCENE)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().size_changed.connect(_fit_screen)
	_fit_screen()
	$Screen/PowerButton.pressed.connect(exit)
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


## Removes every minigame without emitting completed/failed.
func stop_all() -> void:
	for minigame in active_minigames():
		minigame.cleanup()
		minigame.queue_free()


func exit() -> void:
	stop_all()
	var target := GameState.computer_return_scene if GameState.computer_return_scene else FALLBACK_RETURN_SCENE
	GameState.computer_return_scene = ""
	get_tree().change_scene_to_file(target)


## Plain insert mode for now; vim modes come later. Esc is deliberately not an exit.
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


func _refresh_editor() -> void:
	editor.text = buffer + CURSOR
	_refresh_status()


func _refresh_status() -> void:
	var words := buffer.replace("\n", " ").replace("\t", " ").split(" ", false).size()
	status_bar.text = "-- INSERT --    %d words    Score: %d" % [words, GameState.score]

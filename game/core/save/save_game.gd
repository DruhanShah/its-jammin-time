extends Node
## Autoload "SaveGame": one save slot in `user://save.json` (on the web that's the browser's IndexedDB).
## It holds every saved GameState variable (`GameState.to_save()`: story step, switch progress, power,
## unlocks, computer queue, minigames beaten, bank, idle counters, chair time, stray touches,
## kaleidoscope fields, the player's office pose, the narration log, ...), the narrator's played-cue
## set (`once` lines) and the scene to resume in. Everything else is derived from the step when the
## game resumes (`Story.restore()`: the room swap, the ESDF shift, the computer/switch unlocks).
##
## Start menu API: `has_save()`, `continue_game()`, `new_game()`.
## Autosaves (only while a game is running, i.e. in the office, the computer or a switch game, never
## on the title screens): every story step change, every beaten switch game or computer minigame, the
## power going off/on, Quit to title / Quit in the pause menu (`save()`), and closing the window.
## Values are written with JSON.from_native, so Transform3D, StringName and typed containers survive.

## Emitted after every successful write.
signal saved

const PATH := "user://save.json"
const VERSION := 1
## Where a continued game starts: the office at the saved step (a computer step saved at the computer
## re-opens the computer, which carries on with the queued minigame).
const OFFICE := "res://world/office/office.tscn"
const COMPUTER := "res://minigames/computer/computer.tscn"
## The new-game flow (the character design screen, then the intro, then the office).
const NEW_GAME_SCENE := "res://menus/character_select/character_select.tscn"
## Scenes under these folders are "in game": the pause menu works there and autosaves happen.
const GAME_SCENE_PREFIXES: Array[String] = ["res://world/", "res://minigames/"]


func _ready() -> void:
	Story.step_changed.connect(func(_step: Story.Step) -> void: autosave())
	Story.switch_game_changed.connect(func(_id: StringName) -> void: autosave())
	GameState.power_changed.connect(func(_on: bool) -> void: autosave())
	GameState.computer_minigame_finished.connect(func(_id: StringName) -> void: autosave())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave()


## True when there is a save to continue.
func has_save() -> bool:
	return FileAccess.file_exists(PATH)


## True while a game scene (office, computer, switch game) is the current scene.
func in_game() -> bool:
	var scene := get_tree().current_scene
	if not scene:
		return false
	for prefix in GAME_SCENE_PREFIXES:
		if scene.scene_file_path.begins_with(prefix):
			return true
	return false


## Saves now if a game is running (see the top of this script).
func autosave() -> void:
	if in_game():
		save()


## Writes the save. Returns false (and reports the error) if the file can't be written.
func save() -> bool:
	var player := get_tree().current_scene.get_node_or_null(^"Player") if get_tree().current_scene else null
	if player and player.has_method(&"remember_pose"):
		player.remember_pose()
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"scene": _resume_scene(),
		"state": GameState.to_save(),
		"played_cues": Narrator.played_cues(),
	}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveGame: can't write %s (%s)" % [PATH, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(JSON.from_native(data), "\t"))
	file.close()
	saved.emit()
	return true


## Loads the save and goes to its scene (with a fade). Returns false if there's no readable save.
func continue_game() -> bool:
	var data := _read()
	if data.is_empty():
		return false
	Narrator.stop()
	GameState.from_save(data.get("state", {}))
	Narrator.set_played_cues(data.get("played_cues", []))
	Story.restore()
	var scene: String = data.get("scene", OFFICE)
	if scene == COMPUTER:
		GameState.computer_return_scene = OFFICE
	Audio.crossfade_to(Audio.GAME_MUSIC, 0.5, 1.5) # Straight back into the game: skip the menu music.
	Transition.change_scene(scene if ResourceLoader.exists(scene) else OFFICE)
	return true


## Forgets everything (GameState, played lines, the save file) and starts the normal new-game flow.
func new_game() -> void:
	Narrator.stop()
	GameState.reset()
	Narrator.set_played_cues([])
	Story.restart()
	delete_save() # After the restart: its step change autosaves when called from inside a game.
	Transition.change_scene(NEW_GAME_SCENE)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)


## The office, unless we're at the computer in a step that still has minigames to play there.
func _resume_scene() -> String:
	if get_tree().current_scene is Computer and Story.step in Story.MINIGAMES \
			and not GameState.computer_queue.is_empty():
		return COMPUTER
	return OFFICE


func _read() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var data: Variant = JSON.to_native(parsed) if parsed is Dictionary else null
	if not data is Dictionary or not (data as Dictionary).has("state"):
		push_error("SaveGame: %s is unreadable, ignoring it" % PATH)
		return {}
	return data

extends Node
## Autoload "Audio": one-shot sound effects and background music that survives scene changes.
## Process mode Always (audio.tscn): music and SFX keep playing while the tree is paused (pause menu).
##
## Music: the start menu and character select play MENU_MUSIC (they call play_music themselves); the
## character's destruction fades it out (fade_out_music), the intro's black screen is silent, and
## GAME_MUSIC starts when the game proper begins (intro_darkness.gd) and loops for the rest of the game.
## Running any other scene directly (editor F6) starts GAME_MUSIC so the game never runs silent.

## Character select music: "Cheerful Comedy Funny Quirky Background" by alex-morgan (Pixabay).
const MENU_MUSIC := preload("res://assets/audio/music/character_select_cheerful_comedy.ogg")
## In-game BGM: "Piece for Disaffected Piano Two" by Kevin MacLeod (incompetech.com), CC BY 4.0.
const GAME_MUSIC := preload("res://assets/audio/music/piece_for_disaffected_piano_two.ogg")
## Scenes that pick their own music (or silence): the default GAME_MUSIC is not started for them.
const SCENES_WITH_OWN_MUSIC := [
	"res://menus/start_menu/start_menu.tscn",
	"res://menus/character_select/character_select.tscn",
	"res://menus/intro/intro_darkness.tscn",
]

## How much quieter the music gets while the narrator speaks.
@export var duck_db := -12.0
@export var duck_time := 0.3

## Per-track base volume (dB) so the tracks sit at a similar, moderate loudness (the Pixabay track is
## mastered much louder than the solo piano). Streams not listed play at 0 dB.
var _track_db := {
	MENU_MUSIC: -12.0,
	GAME_MUSIC: -4.0,
}
var _base_db := 0.0
var _ducked := false
var _fading_out := false
var _tween: Tween

@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	Narrator.line_started.connect(func(_cue: StringName) -> void: _set_ducked(true))
	Narrator.line_finished.connect(func(_cue: StringName) -> void: _set_ducked(false))
	_start_default_music.call_deferred()


## Plays a one-shot sound on the SFX bus. Use an AudioStreamRandomizer for variations.
func play_sfx(stream: AudioStream, volume_db := 0.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = &"SFX"
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


## Switches the background music. Does nothing if that stream is already playing.
## Loop the stream on import (WAV: Loop Mode = Forward; OGG/MP3: Loop = on).
## fade_in > 0 fades the new track in over that many seconds.
func play_music(stream: AudioStream, fade_in := 0.0) -> void:
	if music.stream == stream and music.playing and not _fading_out:
		return
	_fading_out = false
	_base_db = _track_db.get(stream, 0.0)
	if music.stream != stream or not music.playing:
		music.stream = stream
		music.play()
	if fade_in > 0.0:
		music.volume_db = -60.0
		_tween_volume(_target_db(), fade_in)
	else:
		_kill_tween()
		music.volume_db = _target_db()


func stop_music() -> void:
	_kill_tween()
	_fading_out = false
	music.stop()


## Fades the music out over `time` seconds, then stops it.
func fade_out_music(time := 0.5) -> void:
	if not music.playing:
		return
	_fading_out = true
	_tween_volume(-60.0, time).tween_callback(stop_music)


func _start_default_music() -> void:
	var scene := get_tree().current_scene
	if music.playing or (scene and scene.scene_file_path in SCENES_WITH_OWN_MUSIC):
		return
	play_music(GAME_MUSIC)


func _set_ducked(on: bool) -> void:
	_ducked = on
	if music.playing and not _fading_out:
		_tween_volume(_target_db(), duck_time)


func _target_db() -> float:
	return _base_db + (duck_db if _ducked else 0.0)


## Fades the music player (not the bus, so a volume setting can own the bus) to volume_db.
func _tween_volume(volume_db: float, time: float) -> Tween:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(music, "volume_db", volume_db, time)
	return _tween


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
		_tween = null

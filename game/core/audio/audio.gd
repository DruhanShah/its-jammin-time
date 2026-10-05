extends Node
## Autoload "Audio": one-shot sound effects and background music that survives scene changes.
## Process mode Always (audio.tscn): music and SFX keep playing while the tree is paused (pause menu).

## How much quieter the music gets while the narrator speaks.
@export var duck_db := -12.0
@export var duck_time := 0.3

var _duck_tween: Tween

@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	Narrator.line_started.connect(func(_cue: StringName) -> void: _duck_music(duck_db))
	Narrator.line_finished.connect(func(_cue: StringName) -> void: _duck_music(0.0))


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
func play_music(stream: AudioStream) -> void:
	if music.stream == stream and music.playing:
		return
	music.stream = stream
	music.play()


func stop_music() -> void:
	music.stop()


## Fades the music player (not the bus, so a volume setting can own the bus) to volume_db.
func _duck_music(volume_db: float) -> void:
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_property(music, "volume_db", volume_db, duck_time)

extends Node
## Autoload "Audio": one-shot sound effects and background music that survives scene changes.

@onready var music: AudioStreamPlayer = $Music


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

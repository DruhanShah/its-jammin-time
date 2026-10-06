class_name Minigame
extends Control
## Base for every computer minigame. A minigame only knows how to play itself:
## WHEN it starts is the event manager's job, WHERE it lives is the Computer host's.
## To add one: make a folder under minigames/computer/minigames/, a scene whose root extends
## Minigame, a MinigameConfig subclass + default .tres, and one line in minigame_registry.tres.

signal completed
signal failed
## Ask the host to start another minigame (e.g. an ad that spawns more ads).
@warning_ignore("unused_signal") # Emitted by subclasses (e.g. ad_popup.gd).
signal request_spawn(id: StringName)

## Tunables. The host swaps in a per-instance copy with the caller's overrides applied.
@export var config: MinigameConfig

## Set by the host before begin(). Text minigames read and change computer.buffer.
var computer: Computer
## The registry id this instance was started under. Set by the host.
var id: StringName


## Called once after the host has added this to the screen and injected computer/config.
func begin() -> void:
	pass


## Called right before this minigame is freed, whether it finished or was stopped.
func cleanup() -> void:
	pass


func complete() -> void:
	_end(completed)


func fail() -> void:
	_end(failed)


func _end(result: Signal) -> void:
	if is_queued_for_deletion():
		return
	cleanup()
	result.emit()
	queue_free()

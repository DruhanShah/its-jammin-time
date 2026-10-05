class_name MinigameRegistry
extends Resource
## Maps minigame ids (what the event manager asks for) to their scenes.

@export var entries: Dictionary[StringName, PackedScene] = {}

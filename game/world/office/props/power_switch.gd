extends Node3D
## The switchboard. Its prompt and the scene it opens follow the current switch game
## (`Story.switch_game()`, see minigames/switch/switch_games.gd); while that game is in-world (no
## scene, e.g. gargoyles guarding it) the switch is disabled so the game's own nodes take over.
## The screwed-on cover stays until the screwdriver game is beaten.

@onready var _interactable: Interactable = $Interactable
@onready var _cover: Node3D = $Cover


func _ready() -> void:
	Story.switch_game_changed.connect(_sync.unbind(1))
	_sync()


func _sync() -> void:
	var game := Story.switch_game()
	_interactable.verb = SwitchGames.verb(game)
	_interactable.target_scene = SwitchGames.scene(game) if game else SwitchGames.PLACEHOLDER
	_interactable.enabled = game.is_empty() or not SwitchGames.scene(game).is_empty()
	_cover.visible = Story.step < Story.Step.SWITCH_1 or game == &"screwdriver"

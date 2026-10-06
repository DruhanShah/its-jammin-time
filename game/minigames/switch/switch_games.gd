class_name SwitchGames
## Every switch game (obstacle or restore) by id: the power switch's prompt verb and the scene it
## opens. Which games each blackout plays, in order, is `Story.SWITCH_GAMES`.
## - 2D/3D close-up game: give it a `scene`. When beaten, the scene calls
##   `Story.switch_game_done(id)` then `Transition.change_scene(Story.next_switch_scene())`.
## - In-world game (e.g. gargoyles guarding the switch in the office): `scene = ""`. The power switch
##   is disabled while it's the current game; the game's own node calls `Story.switch_game_done(id)`.
## - No `scene` key = not built yet: opens the placeholder screen, which beats it with one button.

const PLACEHOLDER := "res://minigames/switch/switch_minigame.tscn"

const GAMES := {
	&"screwdriver": {verb = "unscrew the panel", scene = "res://minigames/switch/screwdriver/screwdriver.tscn"},
	&"wires": {verb = "fix the wiring", scene = "res://minigames/switch/wires/wires.tscn"},
	&"gargoyles": {verb = "get past the gargoyles"},
	&"valve": {verb = "turn the valve", scene = "res://minigames/switch/valve/valve.tscn"},
	&"kaleidoscope": {verb = "type the password", scene = "res://minigames/switch/kaleidoscope/keypad.tscn"},
	&"candle": {verb = "light the candle", scene = "res://minigames/switch/candle/candle.tscn"},
}


## Scene that plays game `id`: its own, the placeholder if it isn't built yet, "" if it's in-world.
static func scene(id: StringName) -> String:
	if id.is_empty():
		return ""
	return GAMES.get(id, {}).get("scene", PLACEHOLDER)


static func verb(id: StringName) -> String:
	return GAMES.get(id, {}).get("verb", "flip the switch")

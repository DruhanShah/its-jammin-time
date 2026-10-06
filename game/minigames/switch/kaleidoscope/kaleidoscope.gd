class_name Kaleidoscope
## Switch game "kaleidoscope" (obstacle of the third blackout, see switch_games.gd). A painting next to
## the switch says TWIST ME and shows a shattered mandala (`twist_me_painting.gd`). The binoculars on
## the control desk (`binoculars.gd`) turn out to be a kaleidoscope: looking at the painting through
## them (`ScopeView`) and twisting the barrel with the key ring (`TwistInput`) lines the six wedges up
## until the password reads clearly. The switch then opens a keypad (`keypad.tscn`) that wants it.
## Shared bits live here: the per-step password and how far to twist (`GameState.scope_*`).

const ID := &"kaleidoscope"
const WORDS: Array[String] = ["SPIRAL", "PRETZEL", "TORNADO", "NOODLE", "TWIRL", "DIZZY", "SWIRL", "LOOPY", "WHIRL", "CURLY"]
## Degrees the scope's barrel turns per step of the key ring (one key = 60° of the ring).
const STEP_DEG := 15.0
## Steps in a full turn of the barrel: the wedges line up again every full turn.
const STEPS_PER_TURN := 24
## Twists (in steps) the password can be hidden at, picked by eye from every start frame: near half a
## turn the wedges all land roughly upside down and the word reads fine (just rotated), so those are
## out. 90°..150° and 240°..300°; past half a turn the short way back is anticlockwise.
const TARGETS: Array[int] = [6, 7, 8, 10, 16, 17, 18, 19, 20]


## Picks this step's password and target twist, once (kept until `Story` resets them for a new step).
static func ensure() -> void:
	if GameState.scope_password.is_empty():
		GameState.scope_password = WORDS.pick_random()
		GameState.scope_target = TARGETS.pick_random()


## Signed steps from `steps` to the nearest aligned position (0 = aligned; a full turn aligns again).
static func error_steps(steps: int) -> int:
	@warning_ignore("integer_division")
	var half := STEPS_PER_TURN / 2
	return posmod(steps - GameState.scope_target + half, STEPS_PER_TURN) - half

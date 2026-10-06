extends Node
## Autoload "GameState": small bits of state that must survive scene changes.

## Emitted when an id is unlocked or locked again.
signal unlock_changed(id: StringName, unlocked: bool)
## Emitted when the office power goes out or comes back (see `set_power`).
signal power_changed(on: bool)
## Emitted when the computer finishes one queued minigame (`computer_queue`), i.e. the player beat it.
@warning_ignore("unused_signal") # Emitted by EventManager (minigames/computer/event_manager.gd).
signal computer_minigame_finished(id: StringName)
## Emitted when the computer has played every minigame in `computer_queue`.
@warning_ignore("unused_signal") # Emitted by EventManager.
signal computer_queue_finished

## Where the player stood in each level (by scene path), so returning from a minigame puts them back.
## Each value is [body transform, head pitch].
var player_poses: Dictionary[String, Array] = {}

## Seconds the player has spent pushing chairs, for the narrator's jabs (Player.CHAIR_JABS).
var chair_push_time := 0.0

## Unlocked ids, global across scenes. Ids are snake_case names of the thing, e.g. &"genie_lamp".
var unlocked: Dictionary[StringName, bool] = {}

## Where the story is (`Story.Step`). Change it through `Story`, which reacts to it.
var story_step := 0

## How many switch games of the current switch step are beaten (`Story.SWITCH_GAMES`; reset each step).
var switch_progress := 0

## Kaleidoscope (third blackout, minigames/switch/kaleidoscope/): the password hidden in the TWIST ME
## painting, how many 15° twist steps line it up, whether the binoculars were picked up and whether the
## scope has shown the password. Picked by `Kaleidoscope.ensure()`, reset with each new story step.
var scope_password := ""
var scope_target := 0
var has_scope := false
var scope_solved := false

## False while the lights are out: the office runs on emergency lighting (`world/office/lighting.gd`).
var power_on := true

## Scene to return to when leaving the computer. Set it before switching to the computer scene;
## empty falls back to the office.
var computer_return_scene := ""
## How many pop-up ads the player has closed. Later ads get nastier.
var ads_closed := 0
## Total score from computer minigames. Change it through Computer.add_score() so the screen updates.
var score := 0
## Computer minigames the next computer visit plays, one after another (registry ids, see
## minigames/computer/minigame_registry.tres). Set with Computer.open() / Computer.queue().
## The first entry is removed only once it's beaten, so leaving early resumes it next visit.
## Empty = free use: the computer's EventManager plays its own `start_on_open` list.
var computer_queue: Array[StringName] = []
## When true, the computer goes back to the office by itself once `computer_queue` is done.
var computer_exit_when_done := true
## The password typed at the computer's login (visit 1), so later gags can quote it back. Empty until then.
var password := ""
## Res path of the FontFile chosen in the visit-1 font picker; the computer's document uses it. Empty = default.
var document_font := ""
## Name shown in the word processor's font box for `document_font` (e.g. "Comic Sans"). Empty = none chosen.
var document_font_name := ""
## How often each computer minigame was beaten, by id (counts queued and free-use runs).
var minigames_completed: Dictionary[StringName, int] = {}


func unlock(id: StringName) -> void:
	if not unlocked.has(id):
		unlocked[id] = true
		unlock_changed.emit(id, true)


func lock(id: StringName) -> void:
	if unlocked.erase(id):
		unlock_changed.emit(id, false)


func is_unlocked(id: StringName) -> bool:
	return unlocked.has(id)


## Story switch for the "lights went out" phase: `GameState.set_power(false)` kills the lights,
## `set_power(true)` brings them back. Survives scene changes; the office applies it on load.
func set_power(on: bool) -> void:
	if on != power_on:
		power_on = on
		power_changed.emit(on)


## Symbols the bundled fonts lack (● ✓ ♥ ⌫ ∞ → ▌) fall back to DejaVu Sans. Desktop falls back to
## system fonts anyway, but the web build has none, so without this they draw as boxes. Loaded
## FontFiles are cached and shared, so setting it once covers every scene. Jamdings is left alone.
const SYMBOL_FALLBACK := preload("res://assets/fonts/DejaVuSans-Bold.ttf")
const FONT_DIR := "res://assets/fonts/"
var _fonts: Array[Font] = [] ## Keeps the fonts (and so their fallback) in the resource cache.


func _ready() -> void:
	for file in ResourceLoader.list_directory(FONT_DIR):
		if file.ends_with(".ttf") and not file.begins_with("DejaVu") and not file.begins_with("Jamdings"):
			var font: Font = load(FONT_DIR + file)
			font.fallbacks = [SYMBOL_FALLBACK]
			_fonts.append(font)

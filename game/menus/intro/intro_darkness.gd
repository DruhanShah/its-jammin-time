extends Control
## The black screen after the character is destroyed: two quote cards ("I think, therefore I am." —
## Descartes, then "I think?" — Devs), then the narrator's opening line ("You've finally come to...",
## cue `story_intro`) over warm, comforting darkness, then the game proper begins at the computer (the
## password screen). Click, Enter or Space skips the current card, or the line.

## Quote cards shown before the line, in order: [quote, attribution, seconds held].
const CARDS := [
	["I think, therefore I am.", "— Descartes", 2.5],
	["I think?", "— Devs", 2.0],
]

## Seconds of silent black before the cards, and before and after the line.
@export var lead_in := 1.0
@export var card_gap := 0.6
@export var hold := 0.6
## Seconds each card takes to fade in or out.
@export var card_fade := 0.6

var _leaving := false
var _in_cards := true
var _skip_card := false

@onready var _card: Control = $Card
@onready var _quote: Label = $Card/Quote
@onready var _attribution: Label = $Card/Attribution


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	await get_tree().create_timer(lead_in).timeout
	for card: Array in CARDS:
		await _show_card(card[0], card[1], card[2])
	_in_cards = false
	await get_tree().create_timer(card_gap).timeout
	Narrator.play(&"story_intro")
	if Narrator.current_cue == &"story_intro" and Narrator.is_speaking():
		await Narrator.line_finished
	await get_tree().create_timer(hold).timeout
	_wake()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") or (event is InputEventMouseButton and event.pressed):
		get_viewport().set_input_as_handled()
		if _in_cards:
			_skip_card = true
		else:
			Narrator.stop() # Ends the line, which moves on.


## Fades the card in, holds it for `seconds` (or until skipped), then fades it out.
func _show_card(quote: String, attribution: String, seconds: float) -> void:
	_quote.text = quote
	_attribution.text = attribution
	_skip_card = false
	await _fade_card(1.0)
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until and not _skip_card:
		await get_tree().process_frame
	await _fade_card(0.0)


func _fade_card(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", alpha, card_fade)
	await tween.finished


## The office would send a fresh start straight to the computer; go there directly instead (Story
## then knows the intro was handled, and its own story_intro call is skipped: the cue is `once`).
## Anything else (not a fresh start) goes to the office.
func _wake() -> void:
	if _leaving:
		return
	_leaving = true
	Audio.play_music(Audio.GAME_MUSIC, 2.0) # The game proper begins: its BGM loops from here on.
	Transition.change_scene(Computer.SCENE if Story.take_fresh_start() else Story.OFFICE)

class_name ComicAdConfig
extends AdPopupConfig
## Tunables for the ad storm's comic ad (comic_ad.gd, built on the teammate's ad_popup). Edit
## comic_ad_default.tres; ad_storm.gd picks the variant per spawn through overrides. Overrides are
## scalars on purpose (headline, not headlines): untyped arrays don't fit typed array exports.

enum Variant { PLAIN, RUNNER, NESTED, FAKE_X, COUNTDOWN, ECO }

@export var variant := Variant.PLAIN
## Non-empty overrides the random pick from `headlines` / `decoy_labels`.
@export var headline := ""
@export var body_text := ""
@export var decoy_text := ""
## Word on the wobbling starburst in the top-right corner.
@export var sticker_text := "FREE!"
@export var ad_size := Vector2(380, 250)
## Top-left in the minigame layer; negative = random spot over the document (the parent's behaviour).
@export var spawn_position := Vector2(-1, -1)
## Frame border colour swaps per second.
@export var blink_hz := 2.0

@export_group("Runner")
## Seconds the X takes to hop to another corner (slow enough to read as a joke).
@export var dodge_time := 0.25
## Burst word once the X has used up its dodges.
@export var give_up_word := "FINE."

@export_group("Nested")
## Closing it opens a smaller copy inside, this many levels in total.
@export var nested_depth := 3
@export var nested_scale := 0.75
@export var nested_headlines: Array[String] = [
	"Are you SURE you want to close this ad?",
	"Are you SURE sure?",
	"ok. tiny ad. bye.",
]

@export_group("Fake X")
## Ads each click on the big fake "X CLOSE" spawns (the host still caps them at max_concurrent).
@export var fake_x_spawns := 2
@export var no_thanks_text := "no thanks, I hate saving money"

@export_group("Countdown")
## "Skip ad in N", one step per `countdown_step_time`; a step bigger than the one before is a lie.
@export var countdown_steps: PackedInt32Array = [5, 4, 7, 12]
@export var countdown_step_time := 1.0
@export var countdown_done_text := "Ad skipped itself. You're welcome."

@export_group("Eco")
@export var eco_thanks_text := "Thank you for saving energy!"

@export_group("Comic sounds")
@export var decoy_sfx: AudioStream
@export var dodge_sfx: AudioStream
@export var nested_sfx: AudioStream
@export var tick_sfx: AudioStream
@export var lie_sfx: AudioStream
@export var eco_sfx: AudioStream
@export var eco_sfx_db := -6.0
@export var eco_accept_sfx: AudioStream

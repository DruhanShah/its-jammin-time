class_name AdPopupConfig
extends MinigameConfig
## Tunables for the pop-up ad. Edit ad_popup_default.tres, or override per spawn from the event manager.

## Side length of the real close button, in pixels. Small is the joke.
@export_range(4, 64) var close_button_size := 8.0
## Clicking the ad body or the big fake button spawns another ad.
@export var spawn_on_decoy_click := true
## Once the player has closed this many ads (GameState.ads_closed), the X starts dodging the cursor.
@export var dodge_after_closes := 3
## Most times one ad's X jumps away, so it can always be closed eventually.
@export var max_dodges := 2
## How close (px) the cursor gets to the X before it dodges.
@export var dodge_radius := 20.0
## Seconds of "Skip ad in N" before the X appears. 0 = shows immediately.
@export var skip_countdown := 0.0
@export var headlines: Array[String] = [
	"CONGRATULATIONS! You are the 1,000,000th visitor!",
	"HOT SINGLE SPREADSHEETS in your area",
	"Your PC has 47 viruses! Clean them NOW",
	"Managers HATE this one weird productivity trick",
	"Synergy Pro: leverage your leverage",
]
@export var decoy_labels: Array[String] = ["DOWNLOAD NOW", "CLAIM PRIZE", "CLOSE", "OK", "Continue"]
@export var spawn_sfx: AudioStream
@export var close_sfx: AudioStream

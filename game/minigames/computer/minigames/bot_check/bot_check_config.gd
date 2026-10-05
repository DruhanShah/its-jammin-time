class_name BotCheckConfig
extends MinigameConfig
## Tunables for the "are you a bot?" pop-up. Edit bot_check_default.tres, or override per spawn.

## Seconds before the close X shows up.
@export var close_delay := 3.0
## Chance the "I'm not a robot" checkbox passes on the very first try.
@export_range(0.0, 1.0) var first_try_chance := 0.05
## When the first try doesn't pass, it takes a random number of tries between 2 and this.
@export_range(2, 20) var max_tries := 6
## Seconds the checkbox spins "verifying" before it says pass or fail.
@export var verify_time := 0.8
## Points for passing the captcha.
@export var pass_points := 5
## Points lost for clicking the bot button.
@export var bot_penalty := 10
@export var fail_messages: Array[String] = [
	"Verification failed. Please try again.",
	"Hmm. That's exactly what a robot would click.",
	"Your click was too precise. Try again.",
	"Your click was not precise enough. Try again.",
	"We detected unusual human activity.",
	"Please try again. And mean it this time.",
]
@export var click_sfx: AudioStream

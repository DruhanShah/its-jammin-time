class_name MemoMailConfig
extends MinigameConfig
## Tunables for memo_mail (corporate speak as replies to the boss). Edit memo_mail_default.tres.

## Played in order; the game ends after the last one.
@export var emails: Array[MemoEmail] = []
## Show each blank's options in a random order (otherwise in the order written).
@export var shuffle_options := true
## Add each finished reply to the document being typed.
@export var append_to_document := true
## Seconds the boss's answer stays up before the next email (or the end).
@export var reply_time := 2.8
## The To: line a forced Reply All types out.
@export var reply_all_to := "Entire Company (4,012)"
## The inbox title after a forced Reply All.
@export var reply_all_title := "MemoMail - Inbox (4,012)"
## Replies that pop up after a forced Reply All, one after another ("Sender|text").
@export var reply_all_toasts: Array[String] = []
## Seconds between two Reply All toasts.
@export var toast_interval := 0.25
## Seconds a toast stays up.
@export var toast_time := 4.0
## The second, bigger wave of replies at the very end (it takes the mail server down).
@export var flood_toasts: Array[String] = []
@export var flood_interval := 0.12

@export_group("Narrator cues")
@export var angry_cue := &"memo_angry"
@export var reply_all_cue := &"memo_reply_all"
@export var promoted_cue := &"memo_promoted"
@export var honest_cue := &"memo_honest"

@export_group("Sounds")
@export var arrive_sfx: AudioStream
@export var choose_sfx: AudioStream
@export var mood_up_sfx: AudioStream
@export var mood_down_sfx: AudioStream
@export var send_sfx: AudioStream
@export var reply_all_sfx: AudioStream
@export var toast_sfx: AudioStream
@export var promoted_sfx: AudioStream
@export var honest_sfx: AudioStream

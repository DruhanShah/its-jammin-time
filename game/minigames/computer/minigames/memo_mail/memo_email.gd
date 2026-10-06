class_name MemoEmail
extends Resource
## One email from the boss in `memo_mail`, and how he takes each kind of reply. Edit the emails in
## memo_mail_default.tres.

@export var subject := ""
@export_multiline var body := ""
## The reply the player fills in, in the corporate_speak sentence format:
##   Per my {last email:10|memory:3|vibes:-5}, ...   (each blank: word:points, best to worst)
@export var reply := ""
## People CC'd (shown as a crowd of faces next to the boss); 0 = just the boss.
@export var cc_count := 0
## Reply All presses itself once every blank is filled, and the mail sends itself to everyone.
@export var forced_reply_all := false
## The boss's answer per mood band of the reply: &"angry", &"neutral", &"happy", &"starry".
@export var replies: Dictionary[StringName, String] = {}
## Picking any of these words gets `honest_reply` instead of the mood band's answer.
@export var honest_words: Array[String] = []
@export var honest_reply := ""
## A starry reply to this email gets the boss promoting you (cue, fanfare, "PROMOTED!").
@export var promote_on_starry := false
## Narrator cue played when a word is picked (word → cue id), e.g. {"eepy": &"memo_eepy"}.
@export var word_cues: Dictionary[String, StringName] = {}
## Narrator cue played when this email arrives; empty = none.
@export var arrive_cue: StringName

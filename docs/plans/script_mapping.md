# Script mapping: `docs/narration.md` → narrator cues

Status: planning only (2026-10-06). Apply **after** the current wave merges (gargoyle quiz on master's working tree, antivirus = visit 2, kaleidoscope, candle, ending, start menu / character design; `integrate/wave2` = valve + visit 3 memo_mail + ESDF).

Ground rules for every line below:
- **All lines subtitle-only for now** (`stream` empty). The one exception is the quiz question: `show_subtitle = false` (field added by the gargoyle work, `core/narrator/narrator_cue.gd`, uncommitted on master: it must be merged before this is applied).
- Text is **verbatim** from `docs/narration.md`, except the fixes listed in "Proposed text fixes" (apply only those the user approves).
- `once` is noted per cue. "Existing" = the cue id already exists (on master, `integrate/wave2` or a feature worktree) and only its `subtitle` changes; "NEW" = new `.tres` + trigger code.
- Cue file format: `game/narration/<id>.tres`, `script = ExtResource(narrator_cue.gd)`, `subtitle = "…"`, `once = true` where noted.
- Where a cue lives (as of writing): **M** = master, **W2** = `integrate/wave2`, **AV** = antivirus worktree (`agent-ac397…`), **K** = kaleidoscope worktree (`agent-acdd…`), **C** = candle worktree (`agent-a735…`), **E** = ending worktree (`agent-a2c7…`), **CS** = character select worktree (`agent-a1ee…`), **Q** = gargoyle quiz (master working tree, uncommitted).

## Proposed text fixes (ask the user; otherwise keep verbatim)

| Where | Script text | Proposed | Why |
|---|---|---|---|
| Intro 1 | "…Alas, Life has more to it than this. You must wake" | "…Alas, life has more to it than this. You must wake." | capital L mid-sentence; missing final period (or "You must wake up." / "You must wake—" if the cut-off is deliberate) |
| Intro 5 | "Really? \*That's\* your writing environment?" | "Really? That's your writing environment?" | Markdown italics; the subtitle Label has no BBCode. Already the text of `font_editor_open` |
| Intro 16 | "…making 10 000 dollars a day, … Elon Musk today." | "…making 10,000 dollars a day, … Elon Musk today?" | the subtitle chunker may break between "10" and "000" (or use a no-break space U+00A0); every other "Did you know" line ends with "?" |
| Intro 21 | trailing space after "credits." | trim | — |
| Lights out #1 – 5 | "What's this a Kidz Game?" | "What's this, a Kidz Game?" | optional comma; "Kidz" is deliberate |
| Lights out #1 – 1 | "Oh we also have a server room" | "Oh, we also have a server room" | optional comma |
| Lights out #2 – 1 | "…shouldn't be too hard this time right??" | "…this time, right??" | optional comma |

Everything else (caps, "???", ":D", "corpospeak", "Great Screw Incident of '96", "BRUH.") stays as written.

---

## Intro

| # | Script line (verbatim) | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | You've finally come to. Don't worry, you didn't miss anything. There's just warm, comforting darkness. You find this exciting somehow, like watching paint dry or watching grass grow. Riveting stuff! Alas, Life has more to it than this. You must wake | `story_intro` | existing (M), replace text | ✓ | **Changed trigger:** today it plays when the computer first opens (`Story._on_scene_changed`). It belongs on the **black screen** after the character is destroyed (CS: "cut to black → intro narration → game"). NEW: hold black (e.g. a tiny `wake_up.tscn`: full-screen black ColorRect, `_ready()` plays `story_intro`, changes to the computer on `Narrator.line_finished(&"story_intro")`, any key/click after the first chunk skips) and drop the `_intro_pending` play in `Story._on_scene_changed`. ~19 s of reading. |
| 2 | This is a voice-based password. You can't be this quiet. | `mic_too_quiet` | NEW id (replaces `mic_pastry_bird` + `mic_silent`) | – | `password_scream_config.gd` / default `.tres`: `fail_cues = [&"mic_too_quiet", &""]`, `silent_cue = &"mic_too_quiet"` (verdict of attempt 1, heard or not). Delete `mic_pastry_bird.tres`, `mic_silent.tres`. |
| 3 | Okay you're clearly not loud enough. You'll have to type it in like some kind of caveman. | `password_type_instead` | existing (M), replace text | – | unchanged (text box appears after attempt 2). With `fail_cues[1] = &""` nothing plays on verdict 2, so this isn't cut. Delete `mic_budget_cuts.tres`. |
| 4 | Good morning sunshine! You've decided to work overtime today for some reason, at a comic publisher of all places. You'd have loved to be a stand-up comic, but that doesn't pay the bills so here you are. Well, dreary work builds character or something. Get to it! | `mic_accepted` | existing (M), replace text | ✓ (set) | unchanged (password accepted). **Conflict:** ~19 s line, but the font picker starts 1 s later and `font_editor_open` would cut it. Fix: `password_scream.gd` waits `while Narrator.is_speaking()` (cap ~25 s) before `complete()`; or `font_picker.gd` `begin()` waits for quiet before `open_cue` and swallows picks until then. Prefer the first (the picker never has a line cut by a wrong pick). |
| 5 | Really? *That's* your writing environment? No wonder the company's going under. At least use a more professional font! | `font_editor_open` | existing (M), already this text | ✓ | unchanged |
| 6 | You're going with that? It's no better and you know it. Try again. | `font_wrong` | existing (M), already | – | unchanged (repeats) |
| 7 | Ah the classic. A mark of a true professional. Excellent choice! Now let's do some actual work, shall we? | `font_comic` | existing (M), already | ✓ | unchanged |
| 8 | Here's the server room, with a bunch of servers. They're really just PCs cooled by regular fans. I mean the company's going under, they can't really afford servers. | `room_server` | NEW | ✓ | First time the player is inside the **server-room content** (`Rooms/C1` node, wherever it is: after the SWITCH_2 swap it sits at A3's spot). See "Room-entry lines" below. |
| 9 | Yep, everything's normal here. Don't question it. | `room_upside_down` | NEW | ✓ | first entry into C2 (everything on the ceiling) |
| 10 | Employee of the Month. Don't worry that's not you. | `room_employee_month` | NEW | ✓ | first entry into B2 |
| 11 | Never let it be said that this office is not a family-friendly place. | `room_family_chairs` | NEW | ✓ | first entry into B3 (forced-perspective shrinking desks/chairs + dollhouse) |
| 12 | Gooooaaal! Oh wait wrong game. | `chair_new_room` | existing (M), replace text | ✓ | unchanged: a pushed chair rolls into another room (`Player._check_chair_rooms`) = the "goal". |
| 13 | Just so you know, this isn't the game we have for you. Please play the game. | `chair_push_1` | existing (M), replace text | ✓ | unchanged: 15 s total chair pushing. `chair_push_2` (45 s) has no script line → see "Uncovered cues". |
| 14 | You seem to like waiting around. I think you'd like playing the game a lot more. | `idle_1` | NEW | ✓ | see "Idle lines" |
| 15 | Did you know that sharks have been around for longer than trees? Just passing time. | `idle_2` | NEW | ✓ | idle |
| 16 | Did you know that if you were an Egyptian Pharaoh making 10 000 dollars a day, you still wouldn't have as much money as Elon Musk today. | `idle_3` | NEW | ✓ | idle (text fix proposed) |
| 17 | Did you know that if you dissect a frog on a Sunday, it's still dead on Monday? | `idle_4` | NEW | ✓ | idle |
| 18 | Did you know that life is meaningless without balance and pursuit of the Tao? | `idle_5` | NEW | ✓ | idle |
| 19 | Did you know that the spinal cord has the same consistency as a ripe banana? | `idle_6` | NEW | ✓ | idle |
| 20 | You're not allowed to grab or hold things here. Company policy. Also remember when you tried holding on to your failing relationship? I'm sure there's some Buddhist lesson there. | `no_grabbing` | NEW | ✓ | see "Grab line" |
| 21 | Oh yeah there's just doors here. The devs tried rigging up a Doraemon-style anywhere door, but ran out of Claude credits. | `anywhere_door` | NEW | ✓ | first time the player **opens** one of B1's free-standing doors (`Rooms/B1/Furniture/Door1`, `Door2`, `Door3`, `LastDoor`) — a free-standing door is exactly Doraemon's anywhere door. Optionally also A2's `FakeDoor` (opens onto bare wall). See "Door line". |

## Corpo speak (visit 3 = `memo_mail`, W2)

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | Management has asked us to up our corpospeak rates. You've been given the grunt work. I'll expect this on my metaphorical desk by EOD. | `memo_intro` | existing (W2), replace text | ✓ | unchanged: first email arrives (`Email_1.arrive_cue`). |
| 2 | HR is pleased, I'm sure. I, for one, am disgusted. | `memo_promoted` | existing (W2), replace text | ✓ | today: only email 3 sent with the boss "starry" (`promote_on_starry`). **Proposed:** play on the first send whose band is `happy` or `starry` (any email), once — otherwise most players never hear it. Code: in `memo_mail.gd _send()`, `elif BANDS[band] in [&"happy", &"starry"]: cue = cfg.promoted_cue` (keep the PROMOTED! burst only for `starry and promote_on_starry`). |
| 3 | HR would like a word with you. Tomorrow though. You're safe today, for now. | `memo_angry` | existing (W2), replace text | ✓ | today: the boss's mood first turns red **while filling blanks**. **Proposed:** play on the first send with band `angry` instead (fits "would like a word"; the boss's angry reply bubble already says "HR will be in touch"). Code: in `_send()`, `elif BANDS[band] == &"angry": cue = cfg.angry_cue`, and drop the mid-fill play in the mood setter (line ~122). Keep the mid-fill trigger if the user prefers (zero code). |

## Lights out #1 (SWITCH_1: screwdriver + wires)

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | YOU FELL FOR THAT?? You can't work without the lights! Oh well, let's find some way to fix this, shall we? Usually, where there's lights there's a switch somewhere. Oh we also have a server room, I am sure it exists for a reason. | `lights_out_1` | existing (M), replace text | ✓ | unchanged: office loads dark after the ECO MODE ad → `Computer.blackout()`. Fits right after `ads_eco` ("Don't. Don't press the—"). |
| 2 | You're gonna have to twist these screws out. Try pressing the keys around G in a circle! That's a well-known mechanic, right? | `twist_tutorial` | existing (M), replace text | ✓ | unchanged: first TwistHint ever shown = the screwdriver close-up in a normal run (the antivirus hint sets `intro_cue = &""`; valve/candle come later and the cue is `once`). Only F7 debug skips could make it play in another game. (Alternative, more robust: NEW `screwdriver_intro` set as `intro_cue` on the screwdriver's Hint instance, and `intro_cue = &""` on every other hint; delete `twist_tutorial`.) |
| 3 | That fourth screw was a sticker. We couldn't afford too many screws, so ever since the Great Screw Incident of '96, we've been using stickers. | `screwdriver_sticker` | existing (M), replace text | ✓ | unchanged |
| 4 | Well, looks like we're gonna have to do some hodgepodge electrical work. Pity we don't have an expert among us. | `wires_intro` | existing (M), replace text | ✓ | unchanged (wires close-up opens) |
| 5 | Match the colours?? What's this a Kidz Game? Think straight! | `wires_match_1` | existing (M), replace text | – | unchanged: first colour match (zap). See "Uncovered cues" for `wires_match_2..5`. |
| 6 | Let there be light! The burning glare of the sterile glow hits your eyes once more. You still have work though! Chop chop! | `switch_fixed_1` | existing (M), replace text | ✓ | unchanged: office arrival line after SWITCH_1 (step COMPUTER_2). `wires_done` then has no line → remove it (wires.gd line 108 `Narrator.play(&"wires_done")`; the game already waits for the line before leaving, so the exit gets quicker) or keep as a placeholder. |

## Keyboard shift (third blackout, W2)

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | Dear lord, you messed up your keyboard??? How do you even do that?? Looks like your input is shifted by one character sideways. You'll have to work around it. | `controls_shift` | existing (W2), replace text | ✓ | unchanged: plays when `lights_out_3` finishes (or on the first W/A press while shifted). `lights_out_3` has **no script line** → see Questions. |

## Download antivirus (visit 2, AV)

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | That loading bar doesn't seem to want to do its job. How do you feel about making it twist on your own? | `av_dial_nudge` | existing (AV), replace text | ✓ | today: 8 s on the stuck download screen without clicking the dial, or a ring key pressed before engaging. **Change** `AntivirusDownloadConfig.dial_nudge_after` 8.0 → ~2.5 s so it plays as the screen's opening remark. Then `av_engaged` (placeholder) teaches the keys. |

## Lights out #2 (SWITCH_2: gargoyle quiz + valve)

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | So now we know who's the person downloading viruses on company PCs. Finding the switchboard again shouldn't be too hard this time right?? | `lights_out_2` | existing (M; AV rewrites it), replace text — **overrides AV's placeholder** | ✓ | unchanged (office loads dark after the download) |
| 2 | You misplaced an ENTIRE SERVER ROOM? How does that even happen? I know I'm omniscient and all, but I'm still impressed. | `server_room_empty` | existing (M), replace text | ✓ | unchanged: entering the old C1 location in SWITCH_2. Note the placeholder's direction hint ("near where you started, down and to the right") is lost. |
| 3–8 | Hello, and welcome to Who Wants To Turn On The Lights! Your first question is, Can a Match Box? / And your options are... / 1. Yes / 2. No / 3. No, but a Tin Can / 4. What? | `quiz_question` | **already done (Q)**: text "Hello, and welcome to Who Wants To Turn On The Lights! Your first question is, Can a Match Box? And your options are... 1. Yes. 2. No. 3. No, but a Tin Can. 4. What?", `show_subtitle = false` | – | plays once the slam is over; stopped when an answer is locked. `QuizContent.QUESTION` = "Can a Match Box?", `["Yes", "No", "No, but a Tin Can", "What?"]`, **`correct = 2` ("No, but a Tin Can")** — inferred from the pun, confirm. `quiz_start` was removed by Q. |
| 9 | BRILLIANT! | `quiz_correct` | **already done (Q)** | – | correct answer |
| 10 | BRUH. | `quiz_wrong` | **already done (Q)** (replaces `quiz_wrong_1/2`) | – | every wrong answer |
| 11 | That was all the questions we had. We ran out of budget for more. Thank you for playing Who Wants To Turn On The Lights! | `quiz_passed` | **already done (Q)** | ✓ | quiz passed |
| 12 | That's an odd looking switch, but I guess it's like a valve that lets electricity flow instead of water? Weird system y'all have in this office. | `valve_intro` | existing (W2), replace text | ✓ | unchanged (valve close-up opens) |
| 13 | It's nice and bright again! Time to get back to the headache-inducing computer :D | `switch_fixed_2` | existing (M), replace text | ✓ | unchanged: office arrival after SWITCH_2 (step COMPUTER_3). `valve_done` then has no line → remove the play in valve.gd (`Narrator.play(&"valve_done")`) or keep as placeholder. |

## Lights out #3 (SWITCH_3: kaleidoscope + candle) and the headache

| # | Script line | Cue id | Status | once | Trigger |
|---|---|---|---|---|---|
| 1 | The switch requires a password. It's the year 2026, are you really surprised? | `keypad_intro` | NEW | ✓ | `keypad.gd` `_ready()` (the switch opens the keypad close-up): `Narrator.play(&"keypad_intro")`. Alternative: the first X on the power switch in SWITCH_3. |
| 2 | That's a strange painting you have there. Would be a shame if using that kaleidoscope over there made it make sense. Wink wink. | `twist_me_bare_hands` | existing (K), replace text | ✓ (was not once) | unchanged: X on the TWIST ME painting without the scope (`twist_me_painting.gd`). **Conflict:** it calls the prop a "kaleidoscope" before `scope_pickup`'s "Binoculars! … no. That's a kaleidoscope" reveal, and the prop's prompt says "pick up the binoculars". See Questions. Making it `once` means a 2nd X stays silent; keep not-once if the user prefers. |
| 3 | Oooh trippy. If I'm not wrong, that looks like a password. And I'm usually not wrong. That's one nice perk of omniscience. You should try it sometime. | `scope_solved` | existing (K), replace text | (not once; fine: it only plays on solving) | unchanged |
| 4 | No light switch, but at least there's a candle. It's all we can work with, I suppose. | `keypad_right` | existing (K), replace text | – | unchanged: right password; the keypad waits for the line (max 8 s) then opens the candle. |
| 5 | The twine is too thin to carry wax. You'll have to twist it into something thicker. | `candle_intro` | existing (C), replace text | ✓ | unchanged (candle close-up opens, WICK phase) |
| 6 | Good job. You actually did a dreary job quite well! You'd do splendidly in a wilderness on your own. It's a shame you have bills to pay. | `candle_wick_done` | existing (C), replace text | set ✓ | unchanged: wick fully twisted. (If the team meant "after lighting it", move to a NEW cue on the match catching.) |
| 7 | That's one powerful candle! I don't think you need to know precisely how it works. It's outside your pay grade. | `candle_circuit` | existing (C), replace text | – | unchanged (flame arcs the circuit, lights back) |
| 8 | Okay, this headache is getting a bit much. You can't go much longer without your glasses. Oh yeah you work at a screen, of course you have glasses! | `ending_glasses_hint` | existing (E), replace text | ✓ | unchanged: ENDING step, walking into Start (full blur, spectacles on the desk). `ending_lights_back` (office arrival in ENDING) then has no line → see Uncovered. |

---

## New triggers (specs)

### Room-entry lines (Intro 8–11)
- Where: `StoryStage` (office only, so never in minigames), in the existing 0.5 s `_process` tick next to `_check_server_room` / `_check_off_path`.
- Room lookup by **content**, i.e. the moved room nodes (like `Player._room_at`), so `room_server` fires in the room that holds the server-room content (`Rooms/C1`, at A3's built spot after the SWITCH_2 swap). C2/B2/B3 never move.
- Table: `const ROOM_LINES := {&"C1": &"room_server", &"C2": &"room_upside_down", &"B2": &"room_employee_month", &"B3": &"room_family_chairs"}`.
- Each tick: if the room you're in has a line, `not Narrator.is_speaking()`, and the cue hasn't played → `Narrator.play(cue)` (`once` in the cue does the bookkeeping; while the narrator is talking just retry next tick as long as you're still inside). Optionally require ~0.5 s inside (a doorway graze shouldn't count).
- Priority: in SWITCH_2 at the old C1 location the player is in A3's content, so no clash with `server_room_empty`. Let `room_*` lines suppress the off-path nag for that tick.

### Idle lines (Intro 14–19)
- "Idle" = no player input at all (no key press, no mouse button, mouse motion under a few px) while in the office, `Player.frozen == false`, mouse captured, narrator quiet. Track in `Player` (`idle_time`, reset in `_input` / `_unhandled_input` on any such event) or in `StoryStage`.
- `const IDLE_CUES := [&"idle_1", …, &"idle_6"]`, `idle_first := 30.0` s, `idle_next := 20.0` s of further idleness for each next line. Moving resets the clock but **not** the index (the next idle spell continues with the next fact); stop after `idle_6`. Index kept in `GameState` (or Story) so it survives minigame trips.
- Off-path nags: `StoryStage._check_off_path` should not advance its stall clock while `idle_time > 5 s` (a player standing still is idle, not lost), so the idle lines win.
- Pausing the clock while the narrator talks (like the chair timer) keeps a fact from cutting a line.

### Grab line (Intro 20)
- `Player._touch()`: when the ray hits something (the `touch_sound` branch) and it isn't an Interactable, count `_touches += 1`; on the 2nd such touch (so a single stray click doesn't trigger it) and `not Narrator.is_speaking()` → `Narrator.play(&"no_grabbing")` (`once`). Count in `GameState` if it should survive scene reloads.

### Door line (Intro 21)
- `door.gd`: `@export var open_cue: StringName` (empty default); in `toggle()`, when it starts opening and `open_cue` is set and `not Narrator.is_speaking()` → `Narrator.play(open_cue)`.
- office.tscn: set `open_cue = &"anywhere_door"` on `Rooms/B1/Furniture/Door1`, `Door2`, `Door3`, `LastDoor` (and `Rooms/A2/Furniture/FakeDoor` if the user wants). Edit office.tscn in the editor or with a careful text edit (instance property override lines).

### Keypad intro (Lights out #3 – 1)
- `keypad.gd _ready()`: `Narrator.play(&"keypad_intro")` (`once`). It plays before any wrong-password line, so no clash; `keypad_no_password` (placeholder) still covers typing before solving the painting.

### Wake-up black screen (Intro 1)
- See the Intro table. Coordinate with the start menu / character design branch (it already plans "cut to black → intro narration → game"); if that branch builds the black hold itself, it just plays `story_intro` there and `Story._on_scene_changed` drops its play.

---

## Existing cues the script does NOT cover (decide: keep as placeholder, or remove)

Recommended default in **bold**.

| Cue(s) | Where | Role | Recommendation |
|---|---|---|---|
| `desk_intro` (voiced placeholder WAV) | M, `DeskNarratorTrigger` in Start | walking up to the desk | **remove** (game starts at the computer; overlaps Intro 4's role; the ending branch already disables it in ENDING). Delete the trigger node + cue + WAV, or keep if the user likes it |
| `password_intro` | M | login screen opens | **remove** (`intro_cue = &""`): it would cut Intro 1 if that still plays on the computer, and the screen already says "say your password" |
| `mic_pastry_bird`, `mic_budget_cuts`, `mic_silent` | M | mic verdicts | **remove** (replaced by `mic_too_quiet` / nothing). The on-screen verdict texts ("Did you say: 'pastry bird'?", "Audio received. Audio not processed. (Budget cuts.)") contradict "you can't be this quiet": see Questions |
| `mic_close_refused` | M | X on the login window | keep placeholder |
| `ads_type_nudge`, `ads_first`, `ads_decoy`, `ads_wave_2`, `ads_runner`, `ads_nested`, `ads_countdown`, `ads_eco` | M | ad storm | **keep** (the script has no ad lines; `ads_eco` "Don't. Don't press the—" sets up "YOU FELL FOR THAT??") |
| `chair_push_2` | M | 45 s of chair pushing | keep or remove (script has 2 chair-ish lines, both used) |
| `locked_1..3` | M | X on locked things | **keep** |
| `off_path_1..4` | M | wandering away | **keep** (but see idle priority) |
| `computer_no_power`, `switch_locked` | M | locked computer/switch | **keep** |
| `switch_minigame`, `placeholder_minigame` | M | dev placeholder screens | keep until every switch game is merged, then delete with their scenes |
| `to_be_continued` | M (E deletes it) | end of content | removed by the ending branch |
| `screwdriver_wrong_way` | M | screwing in a screw that's in | keep |
| `wires_match_2..5` | M | further colour matches | **decide**: the wires game is text-free and the narrator is the only hint; `wires_match_1` ("Think straight!") already hints. Option A: keep 2..5 placeholders. Option B: `MATCH_CUES = [&"wires_match_1"]` (repeats every match) and delete 2..5 |
| `wires_crossed`, `wires_straight_first`, `wires_finally` | M | wires reactions | keep |
| `wires_done` | M | lever pulled | **remove** (Lights out #1 – 6 lands on `switch_fixed_1`) |
| `valve_closing`, `valve_reverse_thread`, `valve_righty_early`, `valve_leak` | W2 | valve hints/gags | **keep** (the reverse thread gag needs its hint) |
| `valve_done` | W2 | valve finished | **remove** (Lights out #2 – 13 lands on `switch_fixed_2`) |
| `quiz_phone_friend` | Q | Phone a Friend lifeline | keep ("Pick B" = "No" now, still a wrong steer, which is the joke) |
| gargoyle balloon lines (`QuizContent.LINES`) | Q | Gar/Goyle speech balloons | keep (not narrator; placeholder TODO script) |
| `memo_cc40`, `memo_eepy`, `memo_honest`, `memo_reply_all`, `memo_close_refused` | W2 | memo_mail gags | keep |
| `lights_out_3` | W2 ("Four thousand Reply Alls… The switch is where it was last time: A3.") | third blackout | see Questions |
| `controls_shift_w` | W2 | pressing W after the shift | keep |
| `av_offer_intro`, `av_no_x`, `av_no_x_again`, `av_remind_later`, `av_drag_away`, `av_offer_nudge`, `av_bar_click`, `av_engaged`, `av_slipping`, `av_wrong_way`, `av_dial_again`, `av_halfway`, `av_done` | AV | antivirus | keep (`av_engaged` teaches the keys; the script line only covers the stuck bar) |
| `scope_pickup`, `scope_open`, `scope_almost`, `keypad_no_password`, `keypad_wrong_1/2`, `keypad_twist_me`, `keypad_old_password` | K | kaleidoscope/keypad | keep |
| `candle_match_fizzle` | C | match fizzles | keep |
| `ending_lights_back` | E | office arrival in ENDING | **decide**: keep a short placeholder, or drop it from `ARRIVAL_CUES` so Lights out #3 – 8 (on entering Start) is the first ending line |
| `ending_glasses_nudge_1/2`, `ending_glasses_on`, `credits_end` | E | ending | keep |
| `character_confirm_default`, `character_confirm_random`, `character_destroyed`, `character_rushed` | CS | character design | keep (script has no lines for it) |

## Conflicts with how features work now

1. **Section order vs. flow:** the script's sections are not in play order (Corpo speak is listed second; Keyboard shift sits between Lights out #1 and Download antivirus). The "Beat order" list matches the built flow (Password → Ads → LO1 → Screw + wires → Antivirus → LO2 → server room + quiz (+ valve) → Corpospeak → LO3 → Kaleidoscope + password (+ candle) → Headache → Outro) and doesn't place the keyboard shift. Per the user's decision the shift stays at the **third** blackout, so Keyboard shift 1 → `controls_shift` after `lights_out_3`.
2. **No script line for the third blackout itself** (`lights_out_3`). Lights out #3 – 1 is about the switch's password, i.e. after you reach it.
3. **Intro 1 needs a black screen** that doesn't exist yet (today `story_intro` plays over the computer and `password_intro` cuts it).
4. **Intro 4 is ~19 s and would be cut** by the font picker's `font_editor_open` 1 s after login (fix in the Intro table).
5. **Mic verdict texts on screen** ("pastry bird", "budget cuts") vs. the narrator's "you can't be this quiet / not loud enough".
6. **Lights out #3 – 2 names the "kaleidoscope"** before the binoculars → kaleidoscope reveal (`scope_pickup`); the prop's prompt says "binoculars".
7. **Lights out #2 – 2 drops the direction hint** to the moved server room; the player relies on the mini-map / off-path nags.
8. **Server room entry (Intro 8)** must key off the room content, since C1's content moves to A3 in SWITCH_2.
9. **Idle vs. off-path nags**: standing still also stalls the off-path clock (25 s), which would fire before the idle line (30 s) unless suppressed.
10. **The quiz welcome** ("Hello, and welcome…") is inside the no-subtitle `quiz_question` cue (Q's choice), so it isn't subtitled either; split it into a subtitled cue if wanted.
11. `show_subtitle` lives in master's uncommitted narrator changes (gargoyle work); this mapping depends on that merge.

## Implementation checklist (one agent, after all merges)

1. Confirm merged: gargoyle quiz (with `NarratorCue.show_subtitle`), antivirus (`av_*`, `lights_out_2` rewrite), kaleidoscope (`scope_*`, `keypad_*`, `twist_me_bare_hands`), candle (`candle_*`), ending (`ending_*`, `credits_end`), character select, `integrate/wave2` (valve, memo_mail, ESDF). `ls game/narration/` should contain every "existing" id above.
2. Apply the user's answers to "Proposed text fixes" and the Questions.
3. **Replace subtitles** (keep each file's `once` unless the table says otherwise): `story_intro`, `password_type_instead`, `mic_accepted`, `chair_new_room`, `chair_push_1`, `memo_intro`, `memo_promoted`, `memo_angry`, `lights_out_1`, `twist_tutorial`, `screwdriver_sticker`, `wires_intro`, `wires_match_1`, `switch_fixed_1`, `controls_shift`, `av_dial_nudge`, `lights_out_2`, `server_room_empty`, `valve_intro`, `switch_fixed_2`, `twist_me_bare_hands` (+ `once = true`), `scope_solved`, `keypad_right`, `candle_intro`, `candle_wick_done` (+ `once = true`), `candle_circuit`, `ending_glasses_hint`. Already done by the quiz work: `quiz_question`, `quiz_correct`, `quiz_wrong`, `quiz_passed` (verify only).
4. **Create cues** (all subtitle-only, `once = true`): `mic_too_quiet` (once = false), `room_server`, `room_upside_down`, `room_employee_month`, `room_family_chairs`, `idle_1`..`idle_6`, `no_grabbing`, `anywhere_door`, `keypad_intro`.
5. **Code/config:**
   - `password_scream_config.gd` defaults (or `password_scream_default.tres`): `fail_cues = [&"mic_too_quiet", &""]`, `silent_cue = &"mic_too_quiet"`, `intro_cue = &""`; optionally retune `fail_lines` / `silent_line` (Question 3). `password_scream.gd`: after acceptance wait for the narrator (cap ~25 s) before `complete()`.
   - Wake-up black screen + move `story_intro` (Intro table row 1), unless the character-select branch already does it.
   - `antivirus_download_default.tres` / config: `dial_nudge_after = 2.5`.
   - `memo_mail.gd` `_send()`: promoted cue on happy/starry, angry cue on angry send (if approved).
   - `wires.gd`: drop `wires_done` play; `valve.gd`: drop `valve_done` play (if approved); delete those `.tres`.
   - `keypad.gd _ready()`: play `keypad_intro`.
   - `StoryStage`: room-entry lines (content lookup), idle lines (+ suppress off-path stall while idle), per the specs above.
   - `player.gd`: `idle_time` tracking (if kept in Player) and the `no_grabbing` touch counter.
   - `door.gd`: `open_cue` export; office.tscn: set it on B1's `Door1/2/3`, `LastDoor` (+ A2 `FakeDoor` if approved).
   - Delete removed cues and their references: `mic_pastry_bird`, `mic_budget_cuts`, `mic_silent`, `password_intro` (if removed), `desk_intro` + `DeskNarratorTrigger` + its WAV (if removed), `wires_done`, `valve_done`, plus any the user drops from "Uncovered". `git grep` each id across `game/` (incl. `.tres` configs and `.tscn` `locked_cues`) before deleting.
6. **Verify** (windowed driver on a scratchpad copy, no godot-ai MCP needed): for every touched cue, `Narrator.play(id)` resolves and splits sensibly (`Narrator.split_subtitle`), `quiz_question` shows no subtitle; run the flow with F7: login (both verdicts + type line, Intro 4 not cut by the font line), blackout 1 line, screwdriver tutorial line, wires intro + match line, office arrival lines, antivirus stuck-bar line at ~2.5 s, server room lines (C1 content before and after the swap), quiz lines, valve intro, memo lines, ESDF line, keypad intro, painting, scope, candle, ending hint; idle 30 s in the office → `idle_1`, +20 s → `idle_2`; touch twice → `no_grabbing`; open a B1 door → `anywhere_door`; walk into C2/B2/B3. Game + editor logs clean.
7. **Docs:** `docs/plan.md` "Script joke notes": mark these as final script lines (remove the placeholder notes for replaced ids, list remaining placeholders); engineering log entry for the new triggers; `docs/progress.md` "Script: replace placeholder narrator lines…" → `[x]`.
8. Commit (single-line message, no co-author trailer).

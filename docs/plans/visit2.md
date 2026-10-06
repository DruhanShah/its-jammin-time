# Visit 2 implementation plan: software_update → memo_mail → inky

Source design: `docs/computer_redesign.md` §5 (NEW 2, Improved corporate_speak, NEW 1), §6 row 2, §7 T8–T11. Engineering conventions: `docs/plan.md` ("Adding a minigame", Comic UI kit, `Computer.blackout()`). Visit length target is about 3–4 min: update ~45 s, mail ~90 s, Inky ~75 s.

**Ground rules (apply to all three):**
- Each game lives in `game/minigames/computer/minigames/<id>/` with `<id>.tscn` (root `extends Minigame`), `<id>_config.gd` (`class_name <Name>Config extends MinigameConfig`), `<id>_default.tres` and one registry line. Never start yourself. Call `complete()` once.
- Root = full-rect `Control` (`anchors_preset = 15`, `mouse_filter = IGNORE` unless it must block clicks). Positions come from `size` / `get_viewport_rect()` (1152×648 base, stretch `canvas_items` + `expand`), never hard-coded.
- Windows use `AppWindow` (`pop_in()` on begin, `close(word)` at the end, `closed.connect(complete)`). Bursts use `ComicBurst.spawn(...)`. Text uses the project theme (Comic Neue Bold), with Comic Relief Bold for headings and Comic Shanns Mono for "system" text.
- **No emoji glyphs.** The Comic fonts have none, so faces, stars and bins are drawn with `_draw()`.
- Narrator: subtitle-only `NarratorCue` placeholders in `game/narration/<id>.tres` (`script = narrator_cue.gd`, `subtitle`, `once` as marked). Cue ids go in config fields (as `PasswordScreamConfig` does), so the writers can swap them. `Narrator.play()` interrupts the current line, so keep at least about 2.5 s between cues and gate optional cues on `not Narrator.is_speaking()`.
- Every close X that the game doesn't want used gets `auto_close = false` + `close_requested` → `shake()` + a refusal cue (same pattern as `password_scream._on_close_requested`).

---

## 1. `software_update` (T8, S): the progress bar that won't

**Files:** `minigames/computer/minigames/software_update/{software_update.tscn, software_update.gd, software_update_config.gd, software_update_default.tres, update_bar.gd, percent_chunk.gd}`.

**Scene tree**
```
SoftwareUpdate (Control, full rect, script software_update.gd, config = default.tres)
├─ Backdrop (ColorRect, full rect, halftone.gdshader: paper #1e4fa8, dots #2a63c9, radial = 0)   # "update screen" blue
├─ Center (CenterContainer, full rect, mouse_filter IGNORE)
│  └─ Window (AppWindow, title "ComicOS Update (1 of 1)", auto_close = false, draggable = true)
│     └─ Box (VBoxContainer, separation 14, custom_minimum_size 560×0)
│        ├─ Headline (Label, Comic Relief Bold 26: "Installing updates. Do not turn off your comic.")
│        ├─ Bar (Control, script update_bar.gd, custom_minimum_size 520×48)
│        ├─ Percent (Label, Comic Shanns Mono 22, centred: "63%")
│        ├─ StepText (Label, Comic Neue Italic 18: "Reticulating comics...")
│        └─ SpeedUp (Button "Speed up", pointing-hand cursor)
└─ ChunkLayer (Control, full rect, mouse_filter IGNORE)      # the fallen 1% lives here (not inside the container)
```

**`update_bar.gd`** (`class_name UpdateBar extends Control`). `@export var value := 0.0` (0..100, `queue_redraw` on set) and `var gap := false`. `_draw()`: a black 4 px outline rounded rect, paper fill, 20 vertical segment cells (comic chunky), cells up to `value` filled yellow `#ffd23f` with a black divider every 5%. When `gap` is true the last cell is drawn as an empty dashed hole. `func gap_rect_global() -> Rect2` gives the last cell's rect in global coords, grown by 28 px (generous snap).

**`percent_chunk.gd`** (`extends Control`, `top_level = true`, size 26×48, `mouse_filter = STOP`, pointing-hand cursor). It draws one yellow cell with "1%" on it.
```gdscript
signal dropped(global_center: Vector2)
var velocity := Vector2.ZERO; var falling := false; var dragging := false; var floor_y: float
func fall(from: Vector2, floor: float): global_position = from; velocity = Vector2(randf_range(-120,120), -260); falling = true; floor_y = floor
func _process(d):
    if falling and not dragging:
        velocity.y += 1400.0 * d; global_position += velocity * d; rotation += velocity.x * 0.002 * d
        if global_position.y + size.y >= floor_y:            # bounce on the screen bottom
            global_position.y = floor_y - size.y; velocity.y *= -0.35; velocity.x *= 0.6
            if absf(velocity.y) < 60: falling = false; rotation = lerp_angle(rotation, 0.3, 1.0)  # lies tilted
        global_position.x = clampf(global_position.x, 0, get_viewport_rect().size.x - size.x)
func _gui_input(e):
    if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
        dragging = e.pressed; falling = false; rotation = 0.0
        if not e.pressed: dropped.emit(get_global_rect().get_center())
        accept_event()
    elif e is InputEventMouseMotion and dragging:
        global_position += e.relative; accept_event()       # mouse focus keeps events coming even when the cursor leaves the rect
```

**Phase machine (`software_update.gd`)**: `enum Phase { FORWARD_1, ROLLBACK, FORWARD_2, STUCK, LOOSE, DONE }`
| Phase | Behaviour | Exit |
|---|---|---|
| FORWARD_1 | `value += rate * delta`, `rate = cfg.forward_rate` (8 %/s, eased: ×(1 − value/140)); StepText cycles `cfg.step_texts` every 1.6 s; a tick sound every 5% | value ≥ `cfg.rollback_at` (63) |
| ROLLBACK | Window `shake(6)`, record-scratch, StepText "Rolling back changes...", tween value 63 → 12 over 2.5 s (TRANS_EXPO, EASE_OUT); cue `update_rollback` | tween done |
| FORWARD_2 | as FORWARD_1, but faster (12 %/s) | value ≥ 99 → value = 99 |
| STUCK | StepText "Finalising. Almost. Nearly."; `_stuck_time += delta`; at 4 s, 8 s and 12 s play `update_99` (same non-`once` cue three times); at 16 s `update_99_out` | shake detected **or** `_stuck_time ≥ cfg.auto_fall_after` (22 s) |
| LOOSE | `bar.gap = true`; spawn the chunk at the gap with `fall(gap_pos, ChunkLayer.size.y - 8)`; `update_chunk_fell`; Percent label "99% (1% missing)" | chunk dropped inside `bar.gap_rect_global()` |
| DONE | tween the chunk into the gap (0.15 s, back ease), `bar.gap = false`, value 100, "KA-CHUNK!" burst at the gap, chime; `update_done`; 1.2 s later `window.close("DONE!")`, then `closed` → `complete()` | |

**Speed up button**: during FORWARD_* it multiplies `rate` by 0.5 for 4 s, sets the text to "Speeding up... (slower)" and plays a power-down blip. First press plays `update_speed_up` (once). In STUCK it does nothing except `window.shake(4)`.

**Shake detection** (window drag, no AppWindow change). In `_process`, read `dx = window.position.x - _last_x`. When `absf(dx) > 4` and `signf(dx) != _last_dir`, append `Time.get_ticks_msec()` to `_reversals` and drop entries older than 900 ms. If there are 4 or more reversals, that is a shake: clear the list and call `_on_shake()`. `_on_shake()` in FORWARD_* adds 4% ("Shaking helps. Scientifically.", cue `update_shake` once) with a rattle sound. In STUCK it moves to LOOSE. Because the window is inside a CenterContainer, a re-sort can snap it back. To avoid that, move `Window` out of `Center` once in `begin()` (reparent it to the root and keep its global position). AppWindow's drag clamp already keeps it on screen.

**Dropping the chunk anywhere else**: it falls again, with `update_chunk_missed` (once). If the chunk was dragged above the window, clamp its position to the viewport. Closing the X: `update_close_refused`, plus "Closing during an update voids your warranty."

**Config (`SoftwareUpdateConfig`)**: `forward_rate 8.0`, `forward_rate_2 12.0`, `rollback_at 63.0`, `rollback_to 12.0`, `stuck_lines_at [4,8,12]`, `out_of_encouragement_at 16.0`, `auto_fall_after 22.0`, `shake_reversals 4`, `shake_window_ms 900`, `step_texts` ("Reticulating comics", "Unplugging the sun", "Downloading more Comic Sans", "Asking the lights nicely", "Defragmenting your overtime", "Installing Inky™ (you'll love him)"), all cue ids, and the sounds as `AudioStream` exports.

---

## 2. `memo_mail` (T9, M): corporate speak as replies to the boss

**Respecting PiBot314's work:** `corporate_speak` stays **untouched** and registered (it is still visit 1's placeholder and in `EventManager.start_on_open`). `memo_mail` is a new id that reuses their sentence format and parser, `const CorporateSpeak := preload("res://minigames/computer/minigames/corporate_speak/corporate_speak.gd")`, then `CorporateSpeak.parse(line)` (it's `static`). It also reuses their sentences, word lists, `append_to_document` and `add_score` behaviour.
**Ask the teammate:** (1) Is it OK to call `parse()` from their script, or would they rather move it to a shared `sentence_blanks.gd`? (2) Should `memo_mail` replace `corporate_speak` in `start_on_open` once it lands? (3) Do they want to write or own the email texts? (4) Is it OK that the score stays as "points" behind the mood meter (no number shown)?

**Files:** `memo_mail/{memo_mail.tscn, memo_mail.gd, memo_mail_config.gd, memo_mail_default.tres, memo_email.gd, mood_face.gd, face_crowd.gd}`.
`memo_email.gd`: `class_name MemoEmail extends Resource`. It exports `subject`, `body` (multiline), `reply` (a `{word:points|...}` sentence), `cc_count` (0 or 40), `forced_reply_all` (bool), `replies: Dictionary[StringName, String]` (keys `&"angry", &"neutral", &"happy", &"starry"`), `honest_words: Array[String]`, `honest_reply`, `word_cues: Dictionary[String, StringName]` (e.g. `"eepy": &"memo_eepy"`), `arrive_cue`. The config holds `emails: Array[MemoEmail]` as sub-resources in the `.tres`.

**Scene tree**
```
MemoMail (Control, full rect, script memo_mail.gd)
└─ Center (CenterContainer, full rect)
   └─ Window (AppWindow, title "MemoMail - Inbox (1)", title_color #8fd3ff, auto_close = false)
      └─ HBox (HBoxContainer, separation 18, min 820×420)
         ├─ BossColumn (VBoxContainer, min width 200)
         │  ├─ Boss (Control, mood_face.gd, min 180×180)       # boss avatar: head, tie, face = mood
         │  ├─ Crowd (Control, face_crowd.gd, min 200×130, hidden)  # email 2: 40 tiny faces
         │  └─ MoodLabel (Label, centred: "Boss mood: meh")
         └─ MailColumn (VBoxContainer, separation 10, size_flags_h EXPAND_FILL)
            ├─ Header (GridContainer 2 cols: "From:" "Boss (B. Oss)", "To:" %To, "Subject:" %Subject)
            ├─ Body (Label, autowrap, Comic Neue Regular 18, paper-coloured inset panel)
            ├─ ReplyLabel (Label "Your reply:")
            ├─ Sentence (HFlowContainer, %Sentence)           # same build code as corporate_speak
            ├─ Options (HFlowContainer, %Options, alignment centre)
            └─ Footer (HBoxContainer: %BossReply (Label, italic, EXPAND_FILL) | %ReplyAll (Button "Reply All", disabled) | %Send (Button "Send"))
└─ Toasts (VBoxContainer, bottom-right anchored, mouse_filter IGNORE)   # reply-all flood
```
The blank and option building is copied from `corporate_speak.gd` (`_build`, `_select_blank`, `_choose`), and the `Blank` inner class is re-declared locally (it's an inner class of their script and can't be used through `preload` across scripts in a type-safe way). This is a small duplication of their code, which is the price of not editing their file.

**Mood meter logic**
```gdscript
func _blank_score(b) -> float:            # -1..1 for one blank; 0 while unfilled
    if b.chosen < 0: return 0.0
    var hi := b.best(); var lo := b.worst()  # worst() = min points
    if hi == lo: return 0.0
    return remap(b.points(), lo, hi, -1.0, 1.0)
func _target_mood() -> float:
    var s := 0.0
    for b in _blanks: s += _blank_score(b)
    return clampf(s / _blanks.size(), -1.0, 1.0)
# _process: _mood = lerpf(_mood, _target, 1.0 - exp(-6.0 * delta)); boss.mood = _mood; crowd.mood = _mood
# bands with 0.05 hysteresis: angry < -0.35 ≤ neutral < 0.15 ≤ happy < 0.6 ≤ starry
# band change → boss.bounce() (scale 1.25 → 1 back-ease) + sound (up: chime, down: negative) + MoodLabel text
```
The mood updates **live on every word pick** (from `_choose`), not on Send. The first time it reaches the angry band, play `memo_angry` (once). Picking a word listed in `word_cues` plays that cue (`memo_eepy` once).

**`mood_face.gd`** (`@tool`, `@export var mood := 0.0`): a skin-coloured circle with a 5 px black outline, and a red tie triangle below for the boss. The mouth is a `draw_polyline` arc whose curvature = `mood * 18` px (frown to grin). Below −0.35 add angry brows (two slanted lines) and a red face tint `lerp(skin, #ff6b5b, -mood)`. Above 0.6 the eyes become 5-point stars (polygon) with a sparkle. `bounce()` tweens the scale.
**`face_crowd.gd`** (`@export var mood`, `count := 40`): an 8×5 grid of 22 px faces drawn with the same face routine. Face `i` gets `mood_i = clamp(mood + offset[i], -1, 1)`, with `offset[i] = lerp(-0.6, 0.6, fposmod(i * 0.618, 1.0))` (deterministic spread), so each word flips a few faces. Caption: "CC: 40 people. Happy: 23/40".

**Flow per email** (`_email_index` 0..2):
1. Arrive: the window shakes lightly, an inbox ping plays, `%Subject` and Body fill, the To: label says "Boss", and `arrive_cue` plays (email 1 `memo_intro`, email 2 `memo_cc40`). Email 2 shows `Crowd` (`cc_count` > 0) and To: "Boss; +40 others".
2. The player fills the blanks. Send is enabled when all are filled (as before).
3. **Email 3 (`forced_reply_all`)**: when the last blank is filled, `%Send` is disabled and 0.6 s later `%ReplyAll` "presses itself". It gets its pressed stylebox for 0.15 s, a warning sound plays, and To: types out "Entire Company (4,012)" at 30 chars/s, along with `memo_reply_all` ("Oh. Oh no."). The mail then sends by itself 1.0 s later. After that, 6 toasts pop into `Toasts`, one every 0.25 s with a pop sound each: "RE: who is this", "Please remove me from this list", "+1", "Reply All: STOP replying all", "Out of office until the lights come back", "Sent from my toaster". Each toast is a small comic panel that frees itself after 4 s.
4. Send: a whoosh plays and the body slides up. Then `computer.add_score(total)` and the reply is appended to `computer.buffer` (their separator logic). The boss reply shows in `%BossReply`: if any chosen word is in `honest_words`, use `honest_reply` + cue `memo_honest`; otherwise use `replies[band]`. On email 3 the starry band gives "I have no idea what this means. Promoted." + `memo_promoted` + a brass fanfare + "PROMOTED!" burst. The reply is held for `cfg.reply_time` (2.8 s), then the next email starts or the game ends.
5. After email 3: `window.close("SENT!")`, then `closed` → `complete()`.

**Email content** (placeholders that reuse the teammate's sentences):
| # | Subject | Body | Reply sentence |
|---|---|---|---|
| 1 | Re: Re: Re: Re: why is the deliverable in Comic Sans?? | "Need a status on the comic. Also why is EVERYTHING in Comic Sans. — B." | `Per my {last email:10\|memory:3\|vibes:-5}, the {deliverables:10\|work:3\|chores:0} are {mission-critical:10\|important:3\|whatever:-5}.` |
| 2 (cc 40) | Lights keep going out?? (cc: everyone) | "Team. The lights. Again. Ideas? Reply so everyone can see you care." | `This {paradigm shift:10\|change:3\|mess:-5} will {unlock synergies:10\|help:3\|confuse everyone:-5} across {all verticals:10\|teams:3\|the building:0}.` |
| 3 (reply all) | quick q | "Be honest. Are you happy here?" | `Are you {interested:10\|CRAZY?:1\|eepy:5}? because I {sure am:10\|am too:4\|really hate working here:-5}` (`honest_words = ["really hate working here"]`, honest_reply "Same. Don't tell anyone." — then Reply All means everyone did see it) |

Replies (per email, bands angry/neutral/happy/starry), e.g. email 1: "See me.", "k.", "Great!!", "Love the energy. Still Comic Sans though."

---

## 3. `inky` (T10, M): the assistant you have to get rid of

**Files:** `inky/{inky.tscn, inky.gd, inky_config.gd, inky_default.tres, inky_blot.gd, speech_bubble.gd, recycle_bin.gd, star_rating.gd}`.

**Scene tree**
```
Inky (Control, full rect, mouse_filter IGNORE, script inky.gd)
├─ Doc (PanelContainer, comic paper style, top-centre, min 640×90, hidden until AUTOCORRECT)
│  └─ VBox: Title (Label "Comic Writer — Inky AutoCorrect™ ON") + Words (HFlowContainer, %Words)
├─ Bin (Control, recycle_bin.gd, 96×110, left edge at y 40%, hidden until LOOSE)   # drawn can + lid + "Recycle Bin" label
├─ Rating (AppWindow, title "Rate your assistant!", hidden) → star_rating.gd HBox of 5 drawn stars
├─ Blot (Control, inky_blot.gd, 120×120, mouse_filter STOP)   # Inky himself
└─ Bubble (PanelContainer, speech_bubble.gd)                   # follows Blot; Label + Buttons HBox + tiny X
```
**`inky_blot.gd`**: a blob polygon with 24 points, radius `r * (1 + 0.08 * sin(t*3 + i*1.7))` (wobble), black ink fill with a dark-blue highlight. It has two googly eyes (white circles with a black outline) whose pupils point at `get_global_mouse_position()` (clamped to 6 px), and a pen-nib hat (a gold triangle with a slit). Squash and stretch along the drag velocity. `hop_to(pos)`: an arc tween over 0.35 s (two `tween_method` passes, x linear, y with a −80 px parabola). `signal clicked`, `signal drag_released(global_center)`; dragging is enabled only in LOOSE (same mouse-focus drag as `percent_chunk`).
**`speech_bubble.gd`**: `say(text, buttons: Array[String] = [], closable := false) -> void`, which emits `choice(index)` and `close_pressed`. It's a rounded white panel with a 4 px black outline and a tail drawn toward the blot. It types its text at 40 chars/s with an Inky "blip" every 3 characters, and positions itself above or beside the blot while staying inside the screen.

**State machine** (`enum State { ENTER, OFFER, TIP, AUTOCORRECT, LOOSE, SPAT, RATE, NIGHT_MODE, DONE }`):
| State | Inky does | Player can | Transition |
|---|---|---|---|
| ENTER | Slides up from the bottom-right corner with a boing sound; narrator `inky_intro` ("Oh good, a mascot.") | — | 1.0 s → OFFER |
| OFFER | "It looks like you're writing a comic! Would you like help?" [Yes] [Yes, please] | Click either | → TIP |
| TIP | "Great! Tip: comics are easier to read with words in them!" The bubble has a tiny X (`closable`) | X → Inky **dodges**: hops to the next corner (`CORNERS` cycle TR → BL → TL), "Did you mean: keep Inky?"; first dodge plays `inky_dodge` (once). Clicking Inky: "Hee hee, that tickles." | After `max_dodges` (2) dodges, or 8 s idle → AUTOCORRECT ("Fine! I'll HELP instead!"), with `inky_not_in_script` |
| AUTOCORRECT | Doc pops in with the last sentence of `computer.buffer` (fallback `cfg.fallback_line` "PANEL 1. A man sits at a desk. The lights are on. For now."). Inky hops next to it and "fixes" 3 words one by one, 0.8 s apart (`cfg.corrections`: lights→lies, desk→dusk, comic→comma, overtime→overtired, words→wards; first 3 present, else insert the fallback words). Each changed word becomes a red-underlined Button. `inky_autocorrect` | Click a changed word → it reverts with an eraser sound. **Once** (the first revert), Inky re-corrects it: "Did you mean: lies?" (rule of three) | All 3 reverted → write the sentence back into `computer.buffer` (replace the last line). Inky: "Okay. I'll just sit here then. Forever." → LOOSE |
| LOOSE | Bin pops in; Inky idles in a corner, every 4 s a tip ("Did you know? Light is just dark that tried harder.") | **Drag Inky** (blot is draggable now). Release over `Bin.get_global_rect().grow(20)` → bin. Release elsewhere → Inky hops back to the nearest corner | 1st bin drop → SPAT; 2nd → RATE. Hint: no successful drop for `bin_hint_after` 8 s → `inky_bin_hint` + the bin wiggles. Fallback: `self_bin_after` 30 s → Inky walks into the bin himself ("Fine, I'll do it myself"), which counts as a drop |
| SPAT | Lid closes, bin shakes 0.6 s, a belch sound, "PTOOEY!" burst; Inky flies out in an arc to a corner: "I'm not recyclable! I'm INK!" `inky_bin_spit` | — | 1.5 s → LOOSE (now `_drops = 1`) |
| RATE | Bin balloon: "Inky can't be deleted with fewer than 5 stars. Rate Inky?" Rating window pops in | Hovering star k lights stars 1..k. Clicking k: stars k+1..5 light themselves one by one, 0.15 s apart with a coin sound each: "Did you mean ★★★★★?" (drawn stars, not glyphs). `inky_rate` | 5 stars lit → `Rating.close("THANKS!")` → NIGHT_MODE |
| NIGHT_MODE | Inky hops to centre-right: "Before I go, one last tip! It's late. Turn on **Night Mode** for your eyes?" [Yes] [No] | Yes → night. No → the button twists (rotation 0 → TAU, 0.4 s), its text turns into "Yes" and it presses itself | Night: see below |
| DONE | — | — | `complete()` |

**Night Mode → blackout.** `inky.gd` adds a `ColorRect` named `NightMode` to **`computer.screen`** (not to itself), full rect, `mouse_filter = STOP`, colour `Color(0.06, 0.03, 0.18, 0)`. It then tweens alpha 0 → 0.72 over 1.6 s with a shut-down sound. Inky: "Ahh. Much better for your eyes!" Then narrator `inky_night_mode` ("Inky, no."). Inky shrinks to a dot ("bye!") and `complete()` is called 1.2 s later. EventManager ends the step → queue finished → `Story._on_computer_queue_finished` → `computer.blackout()`. The flicker modulates `screen`, so the overlay flickers with it, and the CRT-off flash is added after it, so it draws on top. **Why the overlay goes on the screen:** `complete()` frees Inky right away, so an overlay inside Inky would vanish and the screen would pop back to bright before the flicker. (In free use with no story, the overlay stays until the player leaves, which is harmless.)

**How the player gets rid of him** (guaranteed): X-dodges are capped at 2, autocorrect needs 3 clicks, the bin needs 2 drops (with a hint at 8 s and Inky self-binning at 30 s), and rating any star count gives 5 stars. Either Night Mode answer gives the blackout. Worst case is about 90 s.

**Config (`InkyConfig`)**: `max_dodges 2`, `tip_idle 8.0`, `correction_interval 0.8`, `corrections: Dictionary[String, String]`, `fallback_line`, `bin_hint_after 8.0`, `self_bin_after 30.0`, `drops_to_rate 2`, `night_alpha 0.72`, `night_fade 1.6`, `tips: Array[String]`, all lines, cue ids, sounds.

---

## 4. Registry, story and wiring (T11, S)

- `minigame_registry.tres`: add `ext_resource`s and the entries `&"software_update"`, `&"memo_mail"` and `&"inky"`. Leave the existing four alone.
- `core/story.gd`: `const SECOND_VISIT: Array[StringName] = [&"software_update", &"memo_mail", &"inky"]`. Nothing else changes: `_go_to(COMPUTER_2)` queues it with `exit_when_done = false`, and when the queue is beaten, `_on_computer_queue_finished` moves to SWITCH_2 and calls `blackout()`. The office then loads dark with `lights_out_2`, and the rooms swap.
- Optional new text for `narration/lights_out_2.tres`: "Darkness again. This time a cartoon ink blot did it. I'd like that on the record." (ask the writers).
- Wallpaper v2 and the clock depend on the T2 desktop, which isn't built (`computer.tscn` is still the vim screen). Skip them; record it as a follow-up in progress.md.
- `docs/progress.md`: mark "Visit 2" `[~]` with sub-items; `docs/plan.md`: add an engineering-log entry per game; `game/CREDITS.md` + `assets/audio/CREDITS.md`: the sounds below.

## 5. Narrator cues (subtitle-only placeholders, `game/narration/`)

| id | once | placeholder subtitle |
|---|---|---|
| update_intro | ✓ | "Updates. The only thing in this office that works overtime besides you." |
| update_speed_up | ✓ | "It's speeding up by slowing down. Like a meeting." |
| update_rollback | | "It's going backwards. That's called a rollback. Or a career." |
| update_shake | ✓ | "Shaking it. The oldest IT technique." |
| update_99 | | "Just a little more." (played 3×) |
| update_99_out | ✓ | "I'm out of encouragement." |
| update_chunk_fell | ✓ | "The last percent fell out. Put it back. Gently." |
| update_chunk_missed | ✓ | "That's the floor. The percent goes in the bar." |
| update_done | ✓ | "One hundred percent. Savour it. It won't happen again." |
| update_close_refused | | "You can't close an update. Updates close you." |
| memo_intro | ✓ | "Corporate speak. A language with no native speakers." |
| memo_angry | ✓ | "He's turning red. That's not a light effect." |
| memo_eepy | ✓ | "Did you just say eepy to your manager." |
| memo_cc40 | ✓ | "Forty people CC'd. Forty faces. Choose your words." |
| memo_reply_all | ✓ | "Oh. Oh no. Everyone saw that." |
| memo_promoted | ✓ | "Promoted. For saying nothing. Beautifully." |
| memo_honest | ✓ | "Honesty. In an email. To four thousand people." |
| memo_close_refused | | "You can't close your inbox. It closes you." |
| inky_intro | ✓ | "Oh good, a mascot." |
| inky_dodge | ✓ | "He dodges. Of course he dodges." |
| inky_not_in_script | ✓ | "He's not in my script. I checked." |
| inky_autocorrect | ✓ | "He's autocorrecting your comic. Into a worse comic." |
| inky_bin_hint | ✓ | "There's a recycle bin. I'm just saying." |
| inky_bin_spit | ✓ | "Even the bin doesn't want him." |
| inky_rate | ✓ | "Rate him. Truthfully. He'll ignore it." |
| inky_night_mode | ✓ | "Inky, no." |

## 6. Sounds (copy unaltered into `game/assets/audio/sfx/...`, import mono where noted, credit)

400 Sounds Pack (Chequered Ink; source `scratchpad/sounds400/extracted/<folder>/<file>`) → `sfx/400_sounds_pack/`. Add each one to the "Files used" list in `assets/audio/CREDITS.md` and update the file count in `game/CREDITS.md`.
| Use | File (pack folder) |
|---|---|
| update tick every 5% (−14 dB) | `Retro/menu_blip.wav` |
| rollback | `Other/record_scratch.wav` |
| speed-up slows it | `Retro/power_down_2.wav` |
| shake rattle | `Card and Board/chips_in_sack_short.wav` |
| 1% falls out / bounces | `Retro/fall_quick.wav`, `Items/tennis_ball_bounce_1.wav` |
| chunk snaps in / update done | `Other/slide_and_click.wav`, `Musical Effects/xylophone_chime_positive.wav` |
| word pick | existing `click_double_on.wav` (teammate's) |
| mood up / down | `Musical Effects/8_bit_chime_positive.wav`, `Musical Effects/8_bit_negative_quick.wav` |
| send / reply-all alarm / toast | `Other/whoosh_2.wav`, `UI/synth_warning.wav`, `UI/pop_3.wav` |
| promoted / honest | `Musical Effects/brass_positive_long.wav`, `Musical Effects/grand_piano_chime_quick.wav` |
| Inky appears / dodge / talk blip | `Retro/jump.wav`, `Other/elastic_twang.wav`, `UI/select_1.wav` |
| Inky dragged / dropped | `Combat and Gore/squelching_3.wav`, `Combat and Gore/splat_quick.wav` |
| autocorrect / revert | `Other/paste.wav`, `Items/pencil_eraser.wav` |
| bin spits him out | `Human/belch_3.wav` |
| star self-fills | `Retro/coin.wav` |
| Night Mode dims | `UI/synth_shut_down.wav` |

Kenney **Interface Sounds** (CC0, `scratchpad/audio2/kenney/interface-sounds/Audio/`, licence `.../interface-sounds/License.txt`) → `sfx/kenney/`: `bong_001.ogg` (new email), `select_002.ogg` (pick up the 1%), `drop_002.ogg` (chunk missed). Add a "Kenney Interface Sounds" section to `assets/audio/CREDITS.md` (author Kenney, https://kenney.nl/assets/interface-sounds, CC0 1.0, files listed) and a row to `game/CREDITS.md`. **Listen to every pick** before shipping (volumes: UI −6 dB, blips −12 dB).

## 7. Test plan

**Static:** `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit` after each game, which must show no parse or load errors (it also imports the new sounds).

**Driver harness** (as in earlier tasks): `rsync -a --delete game/ $SP/v2test/` (keeps `.godot/` so there's no full reimport), drop `drv_<name>.gd` into `$SP/v2test/` and register it as an autoload `_drv="*res://drv_<name>.gd"` in the copy's `project.godot` only. Run it windowed with `Godot --path $SP/v2test` (not headless, so screenshots work) and log to `$SP/v2test/run_<name>.log`. Shared helpers:
```gdscript
func click(p: Vector2):  _btn(p, true); await frames(2); _btn(p, false); await frames(2)
func _btn(p, down):      var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_LEFT; e.pressed = down
                         e.position = p; e.global_position = p; e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0; Input.parse_input_event(e)
func drag(a: Vector2, b: Vector2, steps := 12):
    Input.warp_mouse(a); _btn(a, true); await frames(1)
    for i in steps: var m := InputEventMouseMotion.new(); var p := a.lerp(b, (i + 1.0) / steps)
        m.relative = (b - a) / steps; m.position = p; m.global_position = p; m.button_mask = MOUSE_BUTTON_MASK_LEFT; Input.parse_input_event(m); await frames(1)
    _btn(b, false); await frames(2)
func center(c: Control) -> Vector2: return c.get_global_rect().get_center()
func shot(n): await RenderingServer.frame_post_draw; get_viewport().get_texture().get_image().save_png(OUT + n + ".png")
```
Set `Input.use_accumulated_input = false` in `_ready`. Start each game in isolation with `Computer.queue([&"<id>"], false)` then `get_tree().change_scene_to_file(Computer.SCENE)`, and find the instance with `computer.active_minigames(&"<id>")[0]`.
- **drv_update:** take shots at 30%, during the rollback and at 99%. Shake the title bar (8 drags of ±70 px in 0.5 s) → assert phase LOOSE, wait for the chunk to settle, take a shot. Drag the chunk to a wrong spot and assert it falls again, then drag it onto `bar.gap_rect_global().get_center()` → assert `completed` and take a shot. Second run with no input: assert the chunk falls by itself before 23 s.
- **drv_memo:** find the option Buttons by `text` in `%Options`. Email 1: all-worst picks → assert band angry, take a shot of the red boss; then the best picks → starry, take a shot. Email 2: take a shot of the 40-face crowd at mid mood and assert the happy count changes per pick. Email 3: pick "eepy" (assert the cue fired) and "really hate working here" → assert ReplyAll fired, To: text, 6 toasts, honest reply text, take shots. Assert `computer.buffer` gained 3 sentences and the score changed.
- **drv_inky:** click Yes → click the bubble X twice (assert 2 different corners) → wait for the 3 corrections, then click each (assert the first one re-corrects once) → drag the blot to the bin (assert SPAT) → drag again (assert RATE) → click star 2 (assert 5 lit) → click No (assert it turns into Yes and night) → assert a `NightMode` node exists under `computer.screen` and `completed` fired. Second run: idle in LOOSE → assert the self-bin at 30 s. Take shots of every state.
- **drv_visit2 (end to end):** `Story._go_to(Story.Step.COMPUTER_2)`, then change to `Computer.SCENE`, and play all three with the helpers above. Assert the step is SWITCH_2, `GameState.power_on == false`, the office scene is loaded and dark, `lights_out_2` subtitle shows, and `Story.is_swapped()`. Take a shot of the flicker mid-way (night overlay + CRT).
- **Manual (user):** play with a real mouse and judge pacing, listen to the volumes, and confirm the shake gesture is discoverable. Screenshots go to `$SP/shots_v2/`. Look at every one and judge whether it actually looks comic and readable (plan.md rule).

## 8. Risks / open questions

- **Teammate (PiBot314):** memo_mail depends on `corporate_speak.gd`'s `static parse()` and copies its blank UI. A rename on their branch breaks it, so ask the 4 questions in §2 before merging. Their scene and config are not edited.
- **Shake discoverability:** players may never drag the window. This is covered by the narrator `update_99` lines, the auto-fall at 22 s and the "Speed up" button shaking the window in STUCK. Option: add the StepText hint "Tip: have you tried shaking it?" at 14 s.
- **CenterContainer vs dragging:** a re-sort snaps a dragged AppWindow back to centre. Reparent the window out of the container in `begin()` for update and mail (Inky has no window). The same issue exists in password_scream if it ever re-sorts.
- **Emoji/stars/faces** must be drawn, since Comic fonts don't have them. The "Did you mean ★★★★★?" text uses drawn stars next to the label, not the glyph.
- **Night overlay lifetime:** it must live on `computer.screen` (see §3). Check that `blackout()` doesn't need changes, because its `flash` ColorRect is added later and draws on top.
- **Narrator overlap:** many `once` cues across 3 minutes. Gate the optional ones on the narrator being idle so story beats (`update_99_out`, `memo_reply_all`, `inky_night_mode`) never get cut.
- **Power button mid-visit:** EventManager restarts the current step from scratch on the next visit (no state saved). That's acceptable; mention it in the review notes.
- **Score:** `add_score` is kept for memo_mail, but nobody displays it meaningfully yet (open question 2 in redesign §7).
- **Scope creep:** the ~3–4 min target. If time is short, cut the 40-face crowd (use a single face) and the autocorrect re-correct gag first.

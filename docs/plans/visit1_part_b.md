# Visit 1 part B: font picker + ad storm (ECO MODE blackout)

Implementation plan for `docs/computer_redesign.md` T5 (`font_picker`) and T6 (`ad_storm`), plus the visit-1 wiring. Flow (user): password → **choose a font** (only a Comic font is accepted, the narrator objects to everything else) → **as soon as the player types, ads pop up** → the last ad, **"ECO MODE: TURN OFF LIGHTS"**, causes the blackout.

The plan respects the existing framework. `Minigame`, `EventManager`, the registry and `Computer.blackout()` are used as they are. **The teammate's `ad_popup` files stay untouched**: the new comic ad *inherits* their script.

---

## 0. Files at a glance

| Action | Path (under `game/`) |
|---|---|
| new | `minigames/computer/minigames/font_picker/font_picker.tscn`, `font_picker.gd`, `font_picker_config.gd`, `font_picker_default.tres` |
| new | `minigames/computer/minigames/ad_storm/ad_storm.tscn`, `ad_storm.gd`, `ad_storm_config.gd`, `ad_storm_default.tres`, `typing_sfx.tres` (AudioStreamRandomizer) |
| new | `minigames/computer/minigames/ad_storm/comic_ad.tscn`, `comic_ad.gd` (`extends` ad_popup.gd), `comic_ad_config.gd` (`extends AdPopupConfig`), `comic_ad_default.tres`, `ad_spawn_sfx.tres` (randomizer) |
| modify | `minigames/computer/minigame_registry.tres`: add `font_picker`, `ad_storm`, `comic_ad` |
| modify | `core/story.gd`: `FIRST_VISIT = [&"password_scream", &"font_picker", &"ad_storm"]` |
| modify | `core/game_state.gd`: `var document_font := ""` |
| modify | `minigames/computer/computer.gd`: `apply_document_font()`, `status_note` (both small, see §3) |
| modify | `core/ui/comic/comic_burst.gd`: `ComicBurst.sticker()` (a persistent, non-top-level variant) |
| new | `narration/font_*.tres`, `narration/ads_*.tres` (subtitle-only, §6); update the subtitle of `narration/lights_out_1.tres` |
| new | sounds + credits (§7) |
| docs | `docs/progress.md` (tick Part B), `docs/plan.md` engineering log entry |

---

## 1. Registry, story, persistence

`minigame_registry.tres` gets three more entries: `&"font_picker"`, `&"ad_storm"` and `&"comic_ad"`. `comic_ad` is never queued. Only `ad_storm` spawns it through `computer.start_minigame(&"comic_ad", overrides)`, so every ad is a real Minigame. The host's `max_concurrent` cap, `active_minigames()` and `stop_all()` then all work for the ads automatically.

`story.gd`: `const FIRST_VISIT: Array[StringName] = [&"password_scream", &"font_picker", &"ad_storm"]`. `corporate_speak` leaves visit 1. Leave `SECOND_VISIT`/`THIRD_VISIT` alone, but tell the user that visit 2 is currently `[ad_popup]`, which repeats the storm; `[corporate_speak]` is a better stopgap until T8–T10. The blackout already works: `ad_storm.complete()` → EventManager emits `computer_queue_finished` → `Story._on_computer_queue_finished` → `_go_to(SWITCH_1)` + `computer.blackout()`. The `ad_storm` code never calls `blackout()` itself (in free use / FREE_ROAM it must not cut the power).

`game_state.gd`:
```gdscript
## Res path of the FontFile chosen in the visit-1 font picker; the computer's document uses it. Empty = default.
var document_font := ""
```
We store a path rather than a Font, so GameState stays plain data and is easy to save later.

---

## 2. `font_picker` (T5)

### Scene tree (`font_picker.tscn`)
```
FontPicker (Control, full rect, mouse_filter IGNORE, script font_picker.gd, config font_picker_default.tres)
├ Dim (ColorRect, full rect, Color(0,0,0,0.35), mouse_filter STOP)   # modal: eats clicks on the editor
├ Confetti (CPUParticles2D, one_shot, emitting=false, amount 90, explosiveness 1,
│           direction (0,-1), spread 70, initial_velocity 350–600, gravity (0,900),
│           scale_amount 5–9, color_initial_ramp = 6 comic colours)  # positioned at the chosen row on accept
└ Center (CenterContainer, full rect, mouse_filter IGNORE)
  └ Window (AppWindow, %Window, title "Comic Writer: choose a font", title_color #7ad7ff,
            auto_close=false, draggable=false, close_word "")
    └ Box (VBoxContainer, separation 12)
      ├ Prompt (Label) "Choose a font for your document."
      ├ Body (HBoxContainer, separation 16)
      │ ├ Scroll (ScrollContainer, custom_minimum_size 330×380, horizontal scroll off)
      │ │ └ List (VBoxContainer, %List, separation 2)      # rows built in code
      │ └ PreviewPanel (PanelContainer: paper bg, 3 px black border, radius 10, min 330×380)
      │   └ PreviewBox (VBoxContainer)
      │     ├ PreviewName (Label, %PreviewName, size 16, grey)
      │     ├ Preview (Label, %Preview, size 30, autowrap, text = cfg.preview_text)
      │     └ Note (Label, %Note, size 15, red, autowrap)   # "Licence required", "Disguised", ...
      └ Hint (Label, %Hint, size 14) "Hover to preview, click to use."
```
Screen size is 1152×648, so 12 rows × 40 px won't fit next to the chrome. The list scrolls on purpose: the Comic fonts sit at the **bottom**, and having to scroll down to them is part of the joke.

### Font data (a const in `font_picker.gd`; it's content, but it's code-shaped)
```gdscript
const FONTS: Array[Dictionary] = [
  {name="Times New Roman", system=["Times New Roman","Times","Liberation Serif"], cue=&"font_times",     disguise="Times New Comic"},
  {name="Arial",           system=["Arial","Liberation Sans"],                  cue=&"font_arial",     disguise="Arial Comic"},
  {name="Helvetica",       system=["Helvetica","Helvetica Neue","Arial"],       cue=&"font_helvetica", disguise="Helvetica (Comic Edition)"},
  {name="Calibri",         system=["Calibri","Carlito"],                        cue=&"font_calibri",   disguise="Comicalibri"},
  {name="Garamond",        system=["Garamond","EB Garamond","Georgia"],         cue=&"font_garamond",  disguise="Comic Garamond"},
  {name="Papyrus",         system=["Papyrus"],       cue=&"font_papyrus",  special=true, disguise="Papyrus (but funny)"},
  {name="Impact",          system=["Impact"],                                   cue=&"font_impact",    disguise="Comic Impact"},
  {name="Wingdings",       system=["Wingdings","Webdings"], cue=&"font_wingdings", special=true, disguise="Wingdings Comic Sans"},
  {name="Comic Sans MS",   system=["Comic Sans MS"], licence=true},           # greys out, never accepted
  {name="Comic Neue",        file="res://assets/fonts/ComicNeue-Regular.ttf",       comic=true, cue=&"font_ok_neue"},
  {name="Comic Relief",      file="res://assets/fonts/ComicRelief-Regular.ttf",     comic=true, cue=&"font_ok_relief"},
  {name="Comic Shanns Mono", file="res://assets/fonts/ComicShannsMono-Regular.ttf", comic=true, cue=&"font_ok_mono"},
]
```
`_font_for(entry)`: if `file` → `load(file)`, else `SystemFont.new()` with `font_names = entry.system` and `fallbacks = [ThemeDB.fallback_font]`. We ship no non-Comic fonts. On macOS all of these exist (checked: Times New Roman, Arial, Helvetica, Georgia, Papyrus, Impact, Wingdings, and even Comic Sans MS in `/System/Library/Fonts/Supplemental`; the user's own copy, which we don't distribute). See Risks for the Web.

### Config (`FontPickerConfig extends MinigameConfig`)
`preview_text := "The quick brown fox jumps over the lazy deadline."`, `wobble_after_wrong := 2`, `rename_after_wrong := 3`, `accept_delay := 2.2`, cue ids `wrong_2_cue := &"font_wrong_2"`, `wrong_3_cue := &"font_wrong_3"`, `disguise_cue := &"font_disguise"`, `wrong_more_cues: Array[StringName] = [&"font_wrong_more_1", &"font_wrong_more_2", &"font_wrong_more_3"]`, `licence_cue := &"font_comic_sans_ms"`, `type_first_cue := &"font_type_first"`, `close_refused_cue := &"font_close_refused"`, sounds `hover_sfx`, `wrong_sfx`, `rename_sfx`, `licence_sfx`, `accept_sfx`.

### Script API + key logic (`font_picker.gd extends Minigame`)
```gdscript
var _rows: Array[Button] = []      # same order as FONTS
var _struck := {}                  # index -> true
var _renamed := false
var _wrong := 0
var _said := {}                    # cue -> true (decide lines locally; don't rely on NarratorCue.once returning silently)
var _done := false

func begin():  build rows (flat Button, text = name, font override = _font_for(entry), font_size 24,
               alignment LEFT, min height 38, focus NONE, pointing-hand cursor; connect mouse_entered → _preview(i),
               pressed → _choose(i), draw → _draw_strike.bind(i)); _preview(0); window.hide(); window.pop_in.call_deferred()
               window.close_requested.connect(_on_close_requested)
func _process(d): if _wrong >= cfg.wobble_after_wrong: wobble each un-struck, non-comic row:
               row.pivot_offset = row.size/2; row.rotation = sin(t*9 + i) * 0.035
func _unhandled_key_input(e): swallow every key (set_input_as_handled) so nothing types behind the dialog;
               first key press → _say(cfg.type_first_cue)
func _preview(i): %Preview font override = row font; %PreviewName.text = row.text; %Note per state
               ("Licence required", "Struck out by management", "Disguised"); Audio hover_sfx at -12 dB
func _choose(i):
    if _done: return
    var f := FONTS[i]
    if f.get("comic"): _accept(i); return
    if f.get("licence"): grey out the row (disabled, modulate 0.5), _say(cfg.licence_cue), licence_sfx; return  # not counted
    if _struck.has(i): window.shake(4); return                                      # already rejected
    _wrong += 1
    _struck[i] = true; _rows[i].queue_redraw()                                      # red strike line
    Audio.play_sfx(cfg.wrong_sfx); window.shake(6)
    _say(_wrong_cue(f))
    if _wrong == cfg.rename_after_wrong: _rename_rows.call_deferred()               # after "Let me help."
func _wrong_cue(f) -> StringName:
    if _renamed and f.get("disguise") and not _said.has(cfg.disguise_cue): return cfg.disguise_cue
    if f.get("special") and not _said.has(f.cue): return f.cue                       # Papyrus / Wingdings, any time, once
    match _wrong:
        1: return f.cue
        2: return cfg.wrong_2_cue     # "No."
        3: return cfg.wrong_3_cue     # "Let me help."
        _: return _pick_unrepeated(cfg.wrong_more_cues)
func _rename_rows():  # the "twist": every non-comic, non-licence, un-struck row disguises itself
    _renamed = true; Audio rename_sfx
    for each such row (stagger 0.08 s): tween scale:x 1→0 (0.12, TRANS_BACK EASE_IN), callback text = f.disguise,
        scale:x 0→1 (0.18, TRANS_BACK EASE_OUT), plus rotation_degrees ±8 → 0. The font stays the same (it's a disguise).
func _accept(i):
    _done = true
    GameState.document_font = FONTS[i].file
    if computer: computer.apply_document_font()
    Audio.play_sfx(cfg.accept_sfx); ComicBurst.spawn(self, _rows[i].get_global_rect().get_center(), "KA-CHING!")
    $Confetti.global_position = that centre; $Confetti.restart()
    _say(FONTS[i].cue)
    create_tween().tween_interval(cfg.accept_delay).finished.connect(window.close.bind("NICE!"))
    window.closed.connect(complete)
func _on_close_requested(): window.shake(); _say(cfg.close_refused_cue)
func _say(cue): if cue and not _said.has(cue): _said[cue] = true; Narrator.play(cue)
   # repeatable pool lines (wrong_more) bypass _said: call Narrator.play directly
func _draw_strike(i): if _struck.has(i): row.draw_line(Vector2(4, h/2), Vector2(text_w+8, h/2), Color("#e0201b"), 4)
```
The confetti needs a tween (not a SceneTreeTimer), so it dies with the minigame if Power is pressed.

---

## 3. Small host additions (`computer.gd`)

```gdscript
const DEFAULT_DOCUMENT_FONT := preload("res://assets/fonts/ComicShannsMono-Regular.ttf")
## Text shown in the status bar before the word count (e.g. the ad storm's goal line). Minigames set it.
var status_note := "":
    set(value):
        status_note = value
        if is_node_ready(): _refresh_status()

## Uses GameState.document_font for the document (the visit-1 font picker sets it). Called from _ready().
func apply_document_font() -> void:
    var font: Font = load(GameState.document_font) if GameState.document_font else DEFAULT_DOCUMENT_FONT
    editor.add_theme_font_override(&"normal_font", font)

# _refresh_status(): "-- INSERT --    %s%d words    Score: %d" with (status_note + "    " if status_note else "")
```
T2 (the desktop, planned in parallel) can later move `status_note` into the Comic Writer title bar. Part B only depends on `computer.editor` (its rect), `computer.screen`, `computer.buffer`, `status_note` and `apply_document_font()`.

---

## 4. `comic_ad`: the teammate's ad, inherited and skinned

**Why inherit, not edit:** `ad_popup.gd` already has everything the redesign praises: the tiny X, decoy spawning, the corner dodge, the "Skip ad in N" countdown, shake and pop-in. `comic_ad.gd` starts with `extends "res://minigames/computer/minigames/ad_popup/ad_popup.gd"`, and `ComicAdConfig extends AdPopupConfig`. The ad_popup files and `ad_popup_default.tres` are **not changed**, so visit 2's `ad_popup` and free use behave exactly as before. Ads keep their own garish frame instead of an `AppWindow`, because a big red AppWindow X would kill the tiny-X joke.

### Scene tree (`comic_ad.tscn`)
The parent script needs these unique names: `%Headline`, `%Decoy`, `%CloseButton`, `%Countdown`.
```
ComicAd (Control, 380×250, script comic_ad.gd, config comic_ad_default.tres)
├ Dots (ColorRect, full rect, mouse IGNORE, ShaderMaterial halftone.gdshader: paper #ffe14d, dots #ff5ab4, cell 14, radial 1)
├ Frame (Panel, full rect, mouse IGNORE, StyleBoxFlat: transparent bg, 5 px border, radius 6)   # border colour blinks in code
├ Margin (MarginContainer 18/26/18/14, mouse IGNORE) └ Box (VBoxContainer, sep 8, alignment centre, mouse IGNORE)
│   ├ Headline (Label, %Headline, Comic Relief Bold 26, red #e0201b, outline 6 black, autowrap, centred)
│   ├ Body (Label, %Body, Comic Neue Bold 15, autowrap, centred)
│   ├ Decoy (Button, %Decoy, focus NONE, green #22c55e chunky style: 4 px black border, radius 10, Comic Relief Bold 24, white + black outline)
│   └ NoThanks (Button, %NoThanks, flat, hidden, size 12, underlined-look grey text)   # FAKE_X's real close
├ CloseButton (Button, %CloseButton, focus NONE)   # positioned by the parent's _corner_position()
└ Countdown (Label, %Countdown, hidden, top-right, size 16, black on white pill)
```
`Sticker` is added in code: `ComicBurst.sticker(self, Vector2(size.x - 30, 18), cfg.sticker_text)`. That needs a new static in `comic_burst.gd`: it makes a `persistent` burst (not `top_level`, local position, no puff/free, just a slow ±6° wobble loop). It can't be top_level, because a top_level child doesn't follow the ad when it shakes or slides.

### Config (`ComicAdConfig extends AdPopupConfig`)
```gdscript
enum Variant { PLAIN, RUNNER, NESTED, FAKE_X, COUNTDOWN, ECO }
@export var variant := Variant.PLAIN
@export var headline := ""        # non-empty overrides the random pick (scalar on purpose: see Risks, typed arrays)
@export var body_text := ""
@export var decoy_text := ""
@export var sticker_text := "FREE!"
@export var ad_size := Vector2(380, 250)
@export var spawn_position := Vector2(-1, -1)   # top-left in the layer; negative = random over the editor (parent behaviour)
@export var blink_hz := 2.0
@export_group("Runner") @export var dodge_time := 0.25; @export var give_up_word := "FINE."
@export_group("Nested") @export var nested_depth := 3; @export var nested_scale := 0.75
@export var nested_headlines: Array[String] = ["Are you SURE you want to close this ad?", "Are you SURE sure?", "ok. tiny ad. bye."]
@export_group("Fake X") @export var fake_x_spawns := 2; @export var no_thanks_text := "no thanks, I hate saving money"
@export_group("Countdown") @export var countdown_steps: PackedInt32Array = [5, 4, 7, 12]
@export var countdown_step_time := 1.0; @export var countdown_done_text := "Ad skipped itself. You're welcome."
@export_group("Eco") @export var eco_thanks_text := "Thank you for saving energy!"
@export_group("Comic sounds") decoy_sfx, dodge_sfx, nested_sfx, tick_sfx, lie_sfx, eco_sfx, eco_accept_sfx
```
`comic_ad_default.tres` sets `max_concurrent = 8` (the **hard window cap**: the host returns null beyond 8), `close_button_size = 22` (findable), `dodge_after_closes = 1000` (only RUNNER dodges), `spawn_on_decoy_click = true`, `spawn_sfx = ad_spawn_sfx.tres`, `close_sfx = punch.wav`, the comic sounds, and world-tied `headlines`: "LIGHT BULBS 90% OFF: limited time, limited light", "HOT SINGLE FONTS IN YOUR AREA (Comic Sans wants to meet you)", "Download more overtime FREE", "Your monitor is 3% too bright. Click to fix", "Managers HATE this one weird productivity trick". `decoy_labels`: ["DOWNLOAD NOW", "CLAIM PRIZE", "OK", "Continue"].

### Script (`comic_ad.gd`), overrides only
```gdscript
signal eco_accepted
var _accepted := false

func begin():
    var cfg := config as ComicAdConfig
    size = cfg.ad_size                       # before super: _place_on_screen/_pop_in use size
    if cfg.variant == ComicAdConfig.Variant.RUNNER:
        cfg.dodge_after_closes = 0; cfg.max_dodges = 3; cfg.dodge_radius = 70.0   # config is a per-instance copy
    super.begin()                            # headline/decoy pick, X position, place, pop-in, spawn sfx
    if cfg.headline: headline.text = cfg.headline
    if cfg.body_text: %Body.text = cfg.body_text
    if cfg.decoy_text: decoy.text = cfg.decoy_text
    if cfg.spawn_position.x >= 0.0: position = cfg.spawn_position; _home = position
    ComicBurst.sticker(self, Vector2(size.x - 30, 18), cfg.sticker_text)
    match cfg.variant:
        FAKE_X:    close_button.hide(); decoy.text = "X  CLOSE"; %NoThanks.text = cfg.no_thanks_text
                   %NoThanks.show(); %NoThanks.pressed.connect(_on_close_pressed)
        COUNTDOWN: close_button.hide(); _run_lying_countdown()
        ECO:       _eco_setup()

func _process(delta):  super._process(delta); blink Frame border between #ff2fa0 and #1fd1ff at blink_hz
func _pop_in():       ECO → slide up from below the screen (position.y = screen h → target, 0.55 s TRANS_BACK) + eco_sfx; else super._pop_in()

func _on_close_pressed():
    var cfg := config as ComicAdConfig
    if cfg.variant == ECO: _accept_eco(); return
    if cfg.variant == NESTED and cfg.nested_depth > 1: _open_nested()
    ComicBurst.spawn(get_parent(), close_button.get_global_rect().get_center(), "POW!")
    super._on_close_pressed()                 # ads_closed += 1, close_sfx, complete()

func _open_nested():   # spawned BEFORE this one completes, so the wave never looks "cleared" in between
    var d := cfg.nested_depth - 1
    var child_size := size * cfg.nested_scale
    var idx := clampi(cfg.nested_headlines.size() - d, 0, cfg.nested_headlines.size() - 1)
    computer.start_minigame(id, {"variant": NESTED, "nested_depth": d, "ad_size": child_size,
        "spawn_position": position + (size - child_size) / 2.0, "headline": cfg.nested_headlines[idx],
        "sticker_text": "AGAIN!"})            # null if at the cap: then it just closes
    Audio.play_sfx(cfg.nested_sfx); Narrator.play(&"ads_nested")    # cue is `once`

func _on_decoy():
    match cfg.variant:
        ECO:    _accept_eco()                                       # clicking anywhere is consent
        FAKE_X: _boing(); for i in cfg.fake_x_spawns: request_spawn.emit(id)    # host caps at 8
        _:      _boing(); super._on_decoy()                          # shake + one more ad (teammate's rule)
func _boing(): ComicBurst.spawn(get_parent(), decoy.get_global_rect().get_center(), "BOING!"); Audio decoy_sfx; Narrator.play(&"ads_decoy")

func _dodge():   # replaces the parent's 0.12 s hop with a readable one + a give-up gag
    _dodges_left -= 1; _dodging = true; _corner = (_corner + 1 + randi() % 3) % 4; Audio dodge_sfx
    var t := create_tween(); t.tween_property(close_button, "position", _corner_position(_corner), cfg.dodge_time).set_trans(Tween.TRANS_BACK)
    t.finished.connect(func(): _dodging = false
        if _dodges_left == 0: ComicBurst.spawn(get_parent(), close_button.get_global_rect().get_center(), cfg.give_up_word, Color("#d9d9d9")); Narrator.play(&"ads_runner"))

func _run_lying_countdown():   # "Skip ad in 5… 4… 7… 12…", then it skips itself
    countdown.show(); var t := create_tween()
    for i in cfg.countdown_steps.size():
        var n := cfg.countdown_steps[i]; var lie := i > 0 and n > cfg.countdown_steps[i - 1]
        t.tween_callback(func(): countdown.text = "Skip ad in %d" % n; Audio.play_sfx(cfg.lie_sfx if lie else cfg.tick_sfx)
            if lie: _pop(countdown); Narrator.play(&"ads_countdown"))
        t.tween_interval(cfg.countdown_step_time)
    t.tween_callback(func(): countdown.text = cfg.countdown_done_text)
    t.tween_interval(0.9); t.tween_callback(_on_close_pressed)       # counts as closed

func _eco_setup():  # huge ad over the document
    var area: Rect2 = computer.editor.get_rect(); size = area.size * Vector2(0.9, 0.85)
    position = area.position + (area.size - size) / 2.0; _home = position
    headline.text = "ECO MODE"; headline font size 64 (green #14853b + black outline)
    %Body.text = "Is your office too BRIGHT? Save up to 100% on electricity!"; decoy.text = "TURN OFF LIGHTS" (size 40)
    close_button.size = Vector2.ONE * 6; close_button.position = _corner_position(0)   # microscopic, but it works
    Dots palette → greens; sticker "SAVE 100%!"
func _accept_eco():
    if _accepted: return
    _accepted = true; GameState.ads_closed += 1
    decoy.disabled = true; close_button.hide(); headline.text = cfg.eco_thanks_text; %Body.text = "Lights: OFF. Planet: grateful."
    Audio.play_sfx(cfg.eco_accept_sfx); eco_accepted.emit()      # the ad stays up: it dies with the CRT
```
(The pseudocode uses short names: `cfg` = `config as ComicAdConfig`, `ECO` = `ComicAdConfig.Variant.ECO`, etc.)

---

## 5. `ad_storm` (T6): wave controller + scripted typing

### Scene (`ad_storm.tscn`)
`AdStorm (Control, full rect, mouse_filter IGNORE, script ad_storm.gd, config ad_storm_default.tres)` with no children. It **must not block clicks**, because the ads are its siblings in `MinigameLayer`. It stays alive for the whole beat (it is the EventManager's current step); the ads are separate `comic_ad` instances.

### Config (`AdStormConfig extends MinigameConfig`)
```gdscript
@export_multiline var script_text := "PANEL 1. A man sits at a desk. The lights are on. For now.\n\nMAN: (typing) This is my comic. It is going to be great.\n\nPANEL 2. The man is still typing. Nothing bad has happened yet. Suspicious.\n\nNARRATOR (CAPTION): Nothing bad has happened YET.\n\nPANEL 3. A light bulb, close up. It looks nervous.\n\n"   # ~400 chars; extend
@export var filler := "and then "        # typed in a loop once the script runs out
@export var page_chars := 1800           # "target: 1 page" → the % never gets far (that's the joke)
@export var goal_text := "comic_script_FINAL_final2.cmc · target: 1 page · %d%%"
@export var first_ad_after_keys := 3
@export var wait_typing_idle := 15.0     # nobody types: start wave 1 anyway (nudge cue at 8 s)
@export var next_wave_keys := 6          # after a wave is cleared
@export var next_wave_idle := 8.0
@export var eco_after_keys := 4
@export var eco_idle := 5.0
@export var wave1_headlines: Array[String] = ["LIGHT BULBS 90% OFF: limited time, limited light", "HOT SINGLE FONTS IN YOUR AREA (Comic Sans wants to meet you)", "Download more overtime FREE"]
@export var wave1_gap := 0.6             # s between one wave-1 ad closing and the next
@export var wave2_stagger := 0.3
@export var screen_dip_time := 0.9       # eco: two brightness dips before complete()
@export var type_sfx: AudioStream        # typing_sfx.tres
@export var type_sfx_db := -8.0
# cue ids: nudge_cue &"ads_type_nudge", first_cue &"ads_first", wave2_cue &"ads_wave_2", eco_cue &"ads_eco"
```

### Script (`ad_storm.gd extends Minigame`)
```gdscript
const AD := &"comic_ad"
enum Phase { WAIT_TYPING, WAVE_1, WAIT_2, WAVE_2, WAIT_3, ECO, DONE }
var _phase := Phase.WAIT_TYPING
var _keys := 0           # non-echo keypresses since the phase started
var _idle := 0.0
var _cursor := 0         # next char of script_text
var _wave1_index := 0
var _pending := 0        # ads scheduled but not spawned yet (so a wave never looks cleared too early)
var _last_sfx_ms := 0
var _eco: Minigame

func begin():
    computer.minigame_completed.connect(_on_ad_completed)
    if computer.buffer and not computer.buffer.ends_with("\n"): computer.buffer += "\n"
    _refresh_goal()

func cleanup(): if computer.minigame_completed.is_connected(_on_ad_completed): disconnect

## Emily-is-Away typing: any key writes the next bit of the script.
func _unhandled_key_input(event):
    var key := event as InputEventKey
    if not key.pressed or _phase == Phase.DONE: return
    if key.keycode in [KEY_ESCAPE, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK] or (key.keycode >= KEY_F1 and key.keycode <= KEY_F12) \
        or key.ctrl_pressed or key.meta_pressed: return         # let shortcuts/debug keys (F5–F7) through
    get_viewport().set_input_as_handled()                        # runs before Computer's own typing (child first)
    _type_next()                                                 # Backspace/Enter type too: "it's a script"
    if key.echo: return                                          # holding a key types but doesn't trigger waves
    _keys += 1; _idle = 0.0
    match _phase:
        WAIT_TYPING: if _keys >= cfg.first_ad_after_keys: _start_wave_1()
        WAIT_2:      if _keys >= cfg.next_wave_keys: _start_wave_2()
        WAIT_3:      if _keys >= cfg.eco_after_keys: _start_eco()

func _type_next():
    var chunk := ""
    if _cursor < cfg.script_text.length():
        chunk = cfg.script_text[_cursor]; _cursor += 1
        while _cursor < len and cfg.script_text[_cursor] in [" ", "\n"]: chunk += cfg.script_text[_cursor]; _cursor += 1   # words land on letter keys
    else:
        chunk = cfg.filler[_cursor % cfg.filler.length()]; _cursor += 1
    computer.buffer += chunk
    if Time.get_ticks_msec() - _last_sfx_ms > 40: Audio.play_sfx(cfg.type_sfx, cfg.type_sfx_db); _last_sfx_ms = now
    _refresh_goal()

func _refresh_goal(): computer.status_note = cfg.goal_text % mini(99, 100 * _cursor / cfg.page_chars)

func _process(delta):
    if _phase in [WAIT_TYPING, WAIT_2, WAIT_3]: _idle += delta
    match _phase:   # nobody gets stuck
        WAIT_TYPING: if _idle >= 8.0: Narrator.play(cfg.nudge_cue)  (once)
                     if _idle >= cfg.wait_typing_idle: _start_wave_1()
        WAIT_2:      if _idle >= cfg.next_wave_idle: _start_wave_2()
        WAIT_3:      if _idle >= cfg.eco_idle: _start_eco()

func _enter(phase): _phase = phase; _keys = 0; _idle = 0.0

func _start_wave_1(): _enter(WAVE_1); Narrator.play(cfg.first_cue); _wave1_index = 0; _spawn_wave1()
func _spawn_wave1(): _spawn({"variant": PLAIN, "headline": cfg.wave1_headlines[_wave1_index]})

func _start_wave_2():
    _enter(WAVE_2); Narrator.play(cfg.wave2_cue)
    var r: Rect2 = computer.editor.get_rect()
    var spots := [Vector2(0.04, 0.04), Vector2(0.52, 0.08), Vector2(0.08, 0.50), Vector2(0.55, 0.47)]
    var variants := [RUNNER, NESTED, FAKE_X, COUNTDOWN]
    for i in 4:
        _pending += 1
        _after(i * cfg.wave2_stagger, func(): _pending -= 1
            _spawn({"variant": variants[i], "spawn_position": r.position + r.size * spots[i]}))
    # wave-2 headlines: RUNNER "CATCH ME IF YOU CAN (the X, I mean)", NESTED "Close me. I dare you.",
    # FAKE_X "Your PC is SLOW. Click X to speed up", COUNTDOWN "Watch this 5-second ad about light bulbs" (pass as "headline")

func _start_eco():
    _enter(ECO); Narrator.play(cfg.eco_cue)
    _eco = _spawn({"variant": ECO, "sticker_text": "SAVE 100%!"})
    _eco.eco_accepted.connect(_on_eco_accepted)

func _spawn(overrides) -> Minigame: return computer.start_minigame(AD, overrides)

func _on_ad_completed(id): if id == AD: _check_cleared.call_deferred()

func _check_cleared():
    if _pending > 0 or not computer.active_minigames(AD).is_empty(): return
    match _phase:
        WAVE_1:
            _wave1_index += 1
            if _wave1_index < cfg.wave1_headlines.size():
                _pending += 1; _after(cfg.wave1_gap, func(): _pending -= 1; _spawn_wave1())
            else: _enter(WAIT_2)
        WAVE_2: _enter(WAIT_3)

func _on_eco_accepted():
    _enter(DONE)
    var t := create_tween()      # two brightness dips ("the lights are going"), then the story's blackout takes over
    for i in 2:
        t.tween_property(computer.screen, "modulate", Color(0.45, 0.45, 0.45), cfg.screen_dip_time * 0.25)
        t.tween_property(computer.screen, "modulate", Color.WHITE, cfg.screen_dip_time * 0.25)
    t.tween_callback(_finish)

func _finish():
    if not GameState.computer_queue.has(id): (_eco as ...).complete()   # free use: no blackout, just close it
    complete()                   # story mode: EventManager → computer_queue_finished → Story → computer.blackout()

func _after(s, cb): create_tween().tween_interval(s).finished.connect(cb)    # tween, so it dies with the minigame
```
Timeline for one player: about 3 keys → ad 1 → close ×3 → 6 keys → 4 ads (runner hops 3× then "FINE.", nested 3 deep, fake X spawns at most 2 per click and never more than 8 windows, countdown lies and then skips itself) → 4 keys → ECO slides up, "Don't. Don't press the—" → either button → "Thank you for saving energy!" → 2 dips → flicker → CRT-off → dark office, `lights_out_1`. That's about 60–90 s.

---

## 6. Narrator cues (new `game/narration/<id>.tres`, subtitle-only placeholders)

| id | once | placeholder subtitle |
|---|---|---|
| font_times | ✓ | Times New Roman. For a comic. Bold choice. Wrong, but bold. |
| font_arial | ✓ | Arial. The font of people who have given up, but politely. |
| font_helvetica | ✓ | Helvetica. Very Swiss. Very neutral. Very not a comic. |
| font_calibri | ✓ | Calibri. You didn't choose it. It chose you. Wrong. |
| font_garamond | ✓ | Garamond. For a comic. Are you writing it with a quill? |
| font_papyrus | ✓ | Papyrus is for avatar-themed restaurants. |
| font_impact | ✓ | Impact. For memes. We are not making memes. Officially. |
| font_wingdings | ✓ | Wingdings is not a comic font. It is barely a font. |
| font_comic_sans_ms | ✓ | Comic Sans is licensed by Microsoft. Your employer doesn't pay for licences. Or overtime. |
| font_wrong_2 | | No. |
| font_wrong_3 | ✓ | Let me help. |
| font_disguise | ✓ | That's a disguise. I put it on it. I would know. |
| font_wrong_more_1 | | The answer is in the theme. The theme is comic. |
| font_wrong_more_2 | | I'm not angry. I'm comic. |
| font_wrong_more_3 | | Scroll down. Further. There. The ones that say Comic. |
| font_type_first | ✓ | Font first. Then words. That's the process. |
| font_close_refused | ✓ | You can't close the font dialog without choosing a font. Those are the rules. I wrote them. |
| font_ok_neue | ✓ | Comic Neue. See? You can follow simple instructions. |
| font_ok_relief | ✓ | Comic Relief. Which is exactly what this office needs. |
| font_ok_mono | ✓ | A monospace comic font. For the programmer who also does comics. Or the reverse. |
| ads_type_nudge | ✓ | Type. That's the job. Any key will do. Really, any key. |
| ads_first | ✓ | Oh no. Advertising. In a workplace. Who could have foreseen this. |
| ads_decoy | ✓ | That was an ad pretending to be a button. Like most of management. |
| ads_wave_2 | ✓ | Four more. Your comic is going great, by the way. |
| ads_runner | ✓ | It's scared of you. Respect. |
| ads_nested | ✓ | It had a smaller ad inside it. It's ads all the way down. |
| ads_countdown | ✓ | That countdown is lying. I recognise the technique. I use it on you. |
| ads_eco | ✓ | Don't. Don't press the— |
| lights_out_1 (edit) | | And that is how an advert turned the lights off. You clicked it, though. Remember that. |

File format: copy `narration/password_intro.tres` (`script = narrator_cue.gd`, `subtitle = "..."`, `once = true`). Also add a "TODO script (computer visit 1 part B)" bullet listing these ids to `docs/plan.md` → "Script joke notes", following the existing pattern.

---

## 7. Sounds (exact files + credits)

Copy from the scratchpad (`.../scratchpad/sounds400/extracted/<folder>/<file>` and `.../scratchpad/audio2/...`) into `game/assets/audio/sfx/`. Then run a headless import, and **listen to the volumes / screenshot the result** (team rule).

| Use | Source → destination | Licence |
|---|---|---|
| font hover | 400 `UI/select_1.wav` → `400_sounds_pack/select_1.wav` (-12 dB) | 400 Sounds Pack |
| font wrong pick | `audio2/out/quiz_wrong_buzzer_kevinvg207.wav` → `freesound/` (already cut 0–0.49 s, peak −12 dB) | CC0, "Wrong Buzzer" by KevinVG207, freesound.org/s/331912 |
| rename twist / nested ad | 400 `Retro/wobble.wav` | 400 Sounds Pack |
| Comic Sans MS refused | 400 `UI/cancel.wav` | 400 Sounds Pack |
| font accepted ("KA-CHING!") | 400 `Items/coins_gather_medium.wav` | 400 Sounds Pack |
| typing (`typing_sfx.tres`, randomizer, pitch ±6 %) | 4 single keystrokes cut from 400 `Other/keyboard_typing.wav` (3.6 s) → `400_sounds_pack/keyboard_key_1..4.wav` (~0.08 s each, 5 ms fades; **modified**, say so in credits). Fallback if the cuts sound mushy: Kenney Interface Sounds `click_001/002/003.ogg` → `kenney/` | 400 Sounds Pack / CC0 Kenney |
| ad spawn (`ad_spawn_sfx.tres`) | 400 `UI/pop_1.wav`, `pop_3.wav`, `pop_4.wav` (`pop_2` is AppWindow's) | 400 Sounds Pack |
| ad closed ("POW!") | 400 `Retro/punch.wav` | 400 Sounds Pack |
| decoy / fake X ("BOING!") | 400 `Other/elastic_twang.wav` | 400 Sounds Pack |
| runner X hops | 400 `Retro/jump_short.wav` | 400 Sounds Pack |
| countdown tick / lie | Kenney `interface-sounds/Audio/tick_001.ogg` → `kenney/tick_001.ogg`; lie: 400 `Other/record_scratch.wav` | CC0 Kenney / 400 pack |
| ECO slides in | 400 `Musical Effects/brass_level_start.wav` (2.1 s fanfare, −6 dB) | 400 Sounds Pack |
| ECO accepted | 400 `UI/toggle_off.wav` (then blackout's own crackle + power_down) | 400 Sounds Pack |

Credits: in `game/assets/audio/CREDITS.md`, add these 400-pack files to the "Files used" list (with `keyboard_key_*` marked modified), a **Kenney Interface Sounds 1.0** section (kenney.nl, CC0 1.0, files `tick_001.ogg` [+ clicks if used]) and the KevinVG207 row in the Freesound table. In `game/CREDITS.md`, update the 400-pack row's file count and add rows for Kenney Interface Sounds and "Wrong Buzzer" (KevinVG207, CC0).

---

## 8. Test plan

1. **Parse/import:** `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --import` (creates `.import` for the new sounds), then `--headless --path game --quit` and grep for `SCRIPT ERROR`/`Parse Error`.
2. **Driver script** (scratchpad `v1b_driver.gd`, `extends SceneTree`, same pattern as `test_demo_shot.gd` / `shots_p2.gd`), run **windowed** (headless can't screenshot): `Godot --path game -s <scratchpad>/v1b_driver.gd`. MCP input may not reach the GUI, so the driver feeds input itself:
   - `await process_frame` ×2 (autoloads ready, Story queued FIRST_VISIT), then `Computer.queue([&"font_picker", &"ad_storm"], false)` (skips the mic) and `change_scene_to_file(Computer.SCENE)`. To get the blackout, the Story must stay in step INTRO, which is the default.
   - Picker: `picker._preview(0)`, then `picker._choose(i)` for Times (01), Arial (02, wobble), Impact (03, wait 0.8 s: renamed rows), a disguised row (04), Comic Sans MS (05), Comic Neue (06: KA-CHING + confetti). Screenshot after each with `root.get_texture().get_image().save_png(...)`. Assert `GameState.document_font` ends with `ComicNeue-Regular.ttf` and the editor's font override changed.
   - Real input path: `root.push_input(InputEventKey)` ×3 (keycode/unicode `KEY_A`, pressed then released). Assert `computer.buffer` starts with `"PAN"` and one `comic_ad` is active (07). This proves child-first key handling and that nothing leaks into the free typing.
   - Close the wave-1 ads once with a **real click** (`push_input` mouse motion + button press/release at `close_button.get_global_rect().get_center()`) to check hit-testing; then the rest via `ad.close_button.pressed.emit()` (08).
   - Push 6 keys → 4 ads (09). Runner: call `_dodge()` ×3 and wait 1 s ("FINE.", 10). Nested: close ×3 (11; ad sizes shrink). Fake X: `decoy.pressed.emit()` ×5 → assert `active_minigames(&"comic_ad").size() <= 8` (12). Countdown: screenshot at t≈2.5 s ("Skip ad in 7"/"12", 13).
   - Push 4 keys → ECO (14). `eco.decoy.pressed.emit()` (15: thanks), at +0.5 s (16: dip), +1.2 s (17: flicker/CRT), +3.5 s office (18). Assert `GameState.power_on == false`, `Story.step == Story.Step.SWITCH_1`, and that `lights_out_1` played (`Narrator.current_cue`).
   - Free-use check: run again with `GameState.computer_queue = []` and the EventManager's `start_on_open = [&"ad_storm"]` set on the node before `_ready`: the ECO accept closes the ad, no blackout, `power_on` stays true.
   - Web fallback check: one screenshot of a SystemFont row with `font_names = ["NoSuchFont123"]` to see what the fallback renders (must not be a Comic font).
3. **Judge every screenshot** (team rule): ad readability at 1152×648, no ad covering the subtitles' bottom band for long, sticker not clipping, the ECO ad fully covering the text.
4. **Manual playtest by the user:** full run from a fresh start (mic → font → storm → dark office). Real mouse on the runner, with the narrator lines' timing.
5. Docs: tick Part B in `docs/progress.md` with `[review: ...]` notes, and add the engineering log entry in `docs/plan.md`.

---

## 9. Risks and mitigations

- **Typed-array overrides:** `start_minigame()` applies overrides with `config.set(key, value)`. Passing an untyped `[...]` into an `Array[String]` export can fail. That's why `ComicAdConfig` has scalar `headline`/`body_text`/`decoy_text` fields; pass only scalars, Vector2s and enums as ints.
- **Input order:** this relies on minigames getting `_unhandled_key_input` before the Computer root (child first). `password_scream` already depends on the same thing; the driver's `push_input` test checks it.
- **Mouse blocking:** the `ad_storm` and `font_picker` roots are full-rect: the storm root must be `MOUSE_FILTER_IGNORE`. The picker's `Dim` intentionally stops clicks.
- **The wave looks "cleared" mid-transition:** the nested ad spawns its child before completing, and the `_pending` counter covers the staggered/delayed spawns. `_check_cleared` is deferred.
- **Glyphs:** the Comic fonts lack emoji/symbols (⚡, ✕, 😮‍💨). Use plain text ("ECO MODE", "X  CLOSE") or drawn shapes.
- **SystemFont on Web/Linux:** no system fonts on Web, so the rows fall back. If the fallback resolves to the project theme's Comic Neue, the joke breaks: set `fallbacks = [ThemeDB.fallback_font]` and check with the bogus-name screenshot. If it's still Comic, ship one OFL non-comic font (e.g. Tinos or EB Garamond, small) as the fallback. Wingdings on Web would show letters; acceptable (the line still lands).
- **Key repeat floods:** echoes type but don't count toward triggers; the typing sound is rate-limited to 40 ms.
- **Narrator overlap:** lines interrupt each other. Most storm cues are `once`, and the wave cues play at wave starts only.
- **`GameState.ads_closed` grows by ~10+:** visit 2's teammate `ad_popup` (if it stays in `SECOND_VISIT`) will dodge from its first ad. It's harmless, arguably a callback; mention it to the user.
- **Leaving with Power mid-beat:** `stop_all()` frees the ads, and the beat restarts next visit (the buffer is not persisted; that's the known pending suggestion).
- **Parallel T2 (desktop) work:** Part B touches `computer.gd` only for `status_note` and `apply_document_font()`, and reads `editor`/`screen`/`buffer`. Coordinate if T2 renames these.
- **Free use / FREE_ROAM:** `ad_storm` never calls `blackout()` itself, so there is no power cut outside the story queue.

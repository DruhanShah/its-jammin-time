# Visit 3 implementation plan: antivirus pop-up → crank download → blackout → ESDF

Status: planning only (2026-10-06). Source: `docs/plan.md` "Computer: third visit (user-specified …)"; ESDF details in `docs/plans/esdf_and_web.md` §1 (user decision: the shift happens **at the third blackout**, i.e. when `SWITCH_3` starts). Conventions as in `docs/plans/visit2.md` "Ground rules" (folder per minigame, `Minigame` root, config + default `.tres`, registry line, never start yourself, `complete()` once, no emoji glyphs, subtitle-only placeholder cues, cue ids in config fields, gate optional lines on `not Narrator.is_speaking()`).

**Flow:** the word processor opens → 0.8 s later the **ZappWare** pop-up (no X) → DOWNLOAD → full-screen download screen, stuck at 0 % → click the dial → it becomes a crank → roll the twist ring clockwise (ratchet clicks) → 100 % → "Quarantining 120 lights…" → `complete()` → Story → `Computer.blackout()` → dark office → `lights_out_3` (the antivirus did it) → `controls_shift` (ESDF).

```gdscript
# core/story.gd
const THIRD_VISIT: Array[StringName] = [&"antivirus_offer", &"antivirus_download"]
```
Two ids, not one, so the queue resumes at the download screen if the player presses Power mid-crank (the EventManager keeps unbeaten ids). The 1 s `step_delay` between them is covered by the window's close burst. Add both ids to `minigame_registry.tres`. `bot_check` stays registered (free use).

**Antivirus name** (original, no real brand): **ZappWare Total Defence 3000**, mascot "Zappy" (a shield with a lightning bolt and angry googly eyes). Tagline: "Protects you from everything. Even the things you need." The zap foreshadows the power cut. Alternatives if the team prefers: "VIRUS-B-GONE Ultra", "Defendr Lite", "LumenGuard (lights not included)".

---

## 1. `antivirus_offer` (S): the pop-up without an X

Files: `minigames/computer/minigames/antivirus_offer/{antivirus_offer.tscn, .gd, _config.gd, _default.tres, zappy.gd}`.
```
AntivirusOffer (Minigame, full rect, mouse_filter IGNORE)
├─ Dim (ColorRect #000 a 0.35, full rect, mouse_filter STOP)        # word processor stays visible but dead
├─ Center (CenterContainer, full rect, mouse_filter IGNORE)
│  └─ Window (AppWindow, title "ZappWare Total Defence 3000 - FREE*", closable = false, draggable = true,
│     │        close_word "DOWNLOADING!", title_color #ff4d4d)  # reparent out of Center in begin() (visit2 risk: re-sort snaps it back)
│     └─ Box (VBox, sep 12, min 560×0)
│        ├─ Row (HBox): Zappy (Control 130×150, zappy.gd: _draw shield + bolt + eyes tracking the mouse, ±4° wobble)
│        │              Pitch (VBox): Headline (Comic Relief Bold 30, #d62828) "WARNING! 4,096 VIRUSES DETECTED*"
│        │                            Body (Comic Neue 18, autowrap) "Your comic is UNPROTECTED. ZappWare zaps viruses, malware, bugs and anything else that uses electricity."
│        │                            Fine (Comic Neue Italic 12, grey) "*number made up for marketing purposes"
│        ├─ Download (Button, min 420×64, green #2fbf4a StyleBoxFlat, black 4 px border, Comic Relief Bold 28 "DOWNLOAD NOW (FREE*)", pointing hand; scale pulse 1.0↔1.05 every 0.8 s)
│        └─ Later (LinkButton, grey 14, "Remind me later", centred)
```
- **No X:** `closable = false` hides the AppWindow's button. Draw where it should be: `window.draw.connect(_draw_ghost_x)` draws a dashed 32×32 square at `Rect2(window.size.x - 39, 6, 32, 32)` (same rect the AppWindow uses) with a tiny "X" in 20 % grey, as if it was peeled off. `window.gui_input.connect(_on_window_input)`: a left press inside that rect (grown 10 px) → `window.shake()`, `ComicBurst.spawn(self, global point, "NOPE!")`, cue `no_x_cue` the first time, `no_x_again_cue` after that (only if the narrator isn't talking). Esc → the same refusal (swallow it in `_unhandled_key_input`). All other keys are swallowed while the pop-up is up, so nothing types behind it.
- **Remind me later:** 1st click → its text becomes "Remind me NOW", it hops 30 px, `remind_cue`; 2nd click → same as DOWNLOAD.
- **Drag-away (cheap):** on mouse release after a drag, if less than 50 % of the window is inside the screen → tween it back to centre (0.3 s back ease) + `drag_away_cue` (once).
- **Idle:** `nudge_after` 12 s with no click on the window → Download wiggles (`shake(6)` on it) + `nudge_cue`.
- **DOWNLOAD:** disable both buttons, POW! burst on the button, `window.close()` ("DOWNLOADING!"), `closed` → `complete()`.
- `begin()`: wait `appear_delay` 0.8 s (the player sees the editor first), `window.pop_in()`, `intro_cue`.
- Config `AntivirusOfferConfig`: `appear_delay`, `nudge_after`, the strings above, all cue ids.

## 2. `antivirus_download` (M): the crank-powered download screen

Files: `minigames/computer/minigames/antivirus_download/{antivirus_download.tscn, .gd, _config.gd, _default.tres, crank_dial.gd, download_bar.gd, crank_ratchet.tres}`.

Layout follows the user's reference (structure only): dark textured background; round dial/spinner inside a dark circle on the left; a wide rounded bar with a cream fill and the percentage in big outlined serif-ish text centred on the fill.
```
AntivirusDownload (Minigame, full rect, mouse_filter STOP)        # covers the whole word processor: the installer took over
├─ Backdrop (ColorRect full rect, halftone.gdshader: paper #1b1d22, dots #2a2e36, cell_size 7, radial 0.6) # dark "textured" bg
├─ Center (CenterContainer full rect, mouse_filter IGNORE) └─ VBox (sep 22)
│  ├─ Title (Label, Comic Relief Bold 30, cream #f1e4c3) "ZappWare Total Defence 3000"
│  ├─ File (Label, Comic Shanns Mono 16, #a9a08a) "Downloading ZappWare_Setup_FINAL_v2.exe (4.7 GB)"
│  ├─ Row (HBox, sep 36, align centre)
│  │  ├─ Dial (Control 170×170, crank_dial.gd, mouse_filter STOP, pointing-hand cursor)
│  │  └─ Bar (Control 620×112, download_bar.gd)
│  └─ Status (Label, Comic Shanns Mono 18, #cfc5aa, centred) "Download paused: waiting for user input"
│     Speed (Label, same, smaller) "Speed: 0 RPM · Time remaining: up to you"
├─ Hint (TwistHint instance, anchored under the Dial, arrow_direction 1, intro_cue &"", hidden until engaged)
└─ TwistInput (listen = false)
```
- **`crank_dial.gd`** (`_draw()` only): dark circle `#121316` r 80 with 5 px black outline and 2 px cream rim; a spinner of 12 rounded radial dashes (cream, alpha falling 1.0 → 0.15 around the ring) rotated by `angle`. `engaged` adds a crank: a cream arm from the centre to r 70 with a knob (r 14, black outline) at its end, also rotated by `angle`. While not engaged and idle > 4 s: scale pulse 1.0↔1.08 and a soft glow ring. `signal pressed`: `_gui_input` left press within r 85.
- **`download_bar.gd`** (`_draw()` only): `value` 0..100. Track = pill (`StyleBoxFlat`, corner radius = h/2) `#2a2a2d`, black 5 px border; fill = cream `#efe1bd` pill clipped to `value` (min width = h, so it stays rounded), a darker cream band on its lower third for depth; three small notch ticks at the checkpoints (25/50/75). Percentage: `"%d%%"` in **Tinos Regular** through a `FontVariation` (`variation_embolden 0.9`), size 68, colour `#fff6dc`, `outline_size 16` colour `#16171a`, centred on the fill's centre x, clamped so the text stays inside the track. If it doesn't read as the reference in the screenshot, try EB Garamond, then Comic Relief Bold. `flash()` = brief white fill pulse.
- **States** (`enum Phase { WAITING, CRANKING, DONE }`):
  - **WAITING:** keys do nothing to the bar (ring presses before engaging: `dial_nudge_cue` once). Clicking the Bar → `bar_click_cue` (once, "the circle"). 8 s without engaging → `dial_nudge_cue`. Click the Dial → `engaged = true`, scale pop + `slide_and_click` sound, show Hint, `engaged_cue`, Phase CRANKING, Status "Downloading…".
  - **CRANKING:** `_twist.twisted(delta)`: `percent += delta * cfg.percent_per_degree` (clamped 0..100; `percent_per_degree = 100 / (360 * rotations_to_finish)`, `rotations_to_finish` 5 = 30 key steps, about 15–20 s). `dial.angle += delta * cfg.spin_ratio` (2.0, eased with a 0.08 s tween), ratchet click per step (`crank_ratchet.tres`, `AudioStreamRandomizer`, `random_pitch 1.08`, −6 dB, own `AudioStreamPlayer` with `max_polyphony 4` so fast rolls don't stack nodes), a creak (`foley_creak_1.wav`, −14 dB) every full turn. `Hint.progress = percent / 100`. Bar value tweens to `percent` (0.1 s).
  - **Slip-back:** `slip_delay` 1.0 s with no clockwise step → percent drains at `slip_rate` 6 %/s down to the highest checkpoint passed (25/50/75), the dial unwinds, a slow reverse tick (ratchet at pitch 0.7, every 0.25 s); when it reaches the checkpoint: "clack" (pawl) + small bar shake. First slip → `slipping_cue` (once).
  - **Anticlockwise:** subtracts the same amount (down to the checkpoint too) → `wrong_way_cue` (once); the TwistHint already says "Other way!".
  - **Re-click the dial while cranking** → `dial_again_cue` (once).
  - **Status texts** by percent (config array of `[percent, text]`): 0 "Connecting to ZappWare servers (a hamster)…", 10 "Downloading virus definitions…", 25 "Downloading definitions of the word 'virus'…", 40 "Downloading more crank…", 55 "Unpacking (it brought a lot of luggage)…", 70 "Scanning your office for threats…", 85 "THREAT FOUND: ELECTRICITY (120 sources)" (red), 95 "Preparing to protect you from it…". Speed = clockwise degrees in the last 2 s → RPM (`deg / 360 * 30`), "Time remaining: up to you". At 50 % → `halfway_cue` (once, if quiet). **Avoid a "stuck at 99 %" gag here**: visit 2's `software_update` already uses the 99 %/missing 1 % gag.
  - **DONE** (percent reaches 100): stop listening, `bar.flash()`, `ComicBurst.spawn(self, bar centre, "DING!")`, `synth_process_complete.wav`, `done_cue`; Status "Quarantining 120 lights…" (red), the spinner now spins **on its own** (720°/s: "oh, now it spins by itself"), the bar fill turns red-orange; after `finish_hold` 2.5 s → `complete()`. Story then calls `Computer.blackout()` (its flicker + CRT-off happen on top of this screen). Free use: completes only, no blackout (same as `ad_storm`).
- **Keys (must do):** `Computer._unhandled_key_input` types every key into the document and runs *after* children's `_unhandled_key_input` but *before* any node's `_unhandled_input`, so a listening `TwistInput` would never see the ring. Set `TwistInput.listen = false` and in the minigame's `_unhandled_key_input`: let Esc, F1–F12 and Ctrl/Meta shortcuts through (debug keys), otherwise `_twist.handle(event)` when CRANKING and `set_input_as_handled()` for every key.
- **Power mid-download:** the queue resumes at `antivirus_download` from 0 %. Optional gag: a `static var _attempts` → second time Status starts as "Previous download corrupted. Starting over." (no GameState needed).
- Config `AntivirusDownloadConfig`: `rotations_to_finish 5`, `spin_ratio 2.0`, `slip_delay 1.0`, `slip_rate 6.0`, `checkpoints [25, 50, 75]`, `dial_nudge_after 8.0`, `finish_hold 2.5`, `status_texts`, cue ids, sound exports.

## 3. Blackout, narrator line, ESDF

No new blackout code: `complete()` → EventManager → `GameState.computer_queue_finished` → `Story._on_computer_queue_finished()` → `_go_to(SWITCH_3)` → `Computer.blackout()` → `set_power(false)` → arrival cue `lights_out_3` → office loads dark and `StoryStage` plays it. **Rewrite `narration/lights_out_3.tres`** to blame the antivirus (keeps the old "server room didn't move" joke as a short tail, which plan.md's TODO asked for).

ESDF exactly as `esdf_and_web.md` §1 (implement in the same task):
- New `game/core/input/controls.gd` (`class_name Controls`, `SHIFTED` = move_forward E, move_left S, move_back D, move_right F, interact C, by `physical_keycode`; `set_shifted(on)` reloads the project InputMap then erases/adds events and `Input.action_release`s them).
- `story.gd`: `_sync_controls(new_step)` in `_go_to` → `Controls.set_shifted(step >= Step.SWITCH_3)` (F7 skips, reloads and a new game stay correct), `_controls_cue_pending` set on the false → true edge; `Narrator.line_finished` → after `lights_out_3`, play `controls_shift`; fallback in `_unhandled_input`: first physical W/A press while shifted → `controls_shift` if still pending, else `controls_shift_w` (once). Debug builds: `debug_toggle_controls` on **F8** (add to project.godot through the editor's Input Map).
- The swap happens while the player is at the computer (keys there are raw typing, not actions), so it is invisible until the dark office loads. The HUD prompt becomes "Press C to …" by itself (`PlayerHud.key_name()`).
- **F-key clash:** F is now `move_right` *and* a twist-ring key (the ring is not remapped). Movement is polled, so input handling can't block it. SWITCH_3's switch games (`kaleidoscope`, `candle`) are twist games after the shift, so each must run as a close-up scene without a Player (like `screwdriver`) or set a `Player.movement_locked` flag while its TwistInput listens. Add this note to `kaleidoscope_and_candle.md` when building those. The crank itself is before the shift, so no clash.

## 4. Narrator cues (subtitle-only placeholders in `game/narration/`; add all ids to plan.md's TODO-script list)

| id | once | placeholder line |
|---|---|---|
| `av_offer_intro` | ✓ | "Oh look, a free antivirus. Nothing free has ever gone wrong in this office." |
| `av_no_x` | ✓ | "Looking for the X? There isn't one. They're very confident in their product." |
| `av_no_x_again` | | "Still no X. Clicking harder won't grow one." |
| `av_remind_later` | ✓ | "'Remind me NOW.' That's not how reminders work. It's how ZappWare works." |
| `av_drag_away` | ✓ | "You can't drag it off the screen. It lives here now." |
| `av_offer_nudge` | ✓ | "The big green button. It isn't going anywhere. Neither are you." |
| `av_bar_click` | ✓ | "That's the bar. The bar is decorative. Try the circle." |
| `av_dial_nudge` | ✓ | "It isn't downloading by itself. Nothing here does. Click the circle." |
| `av_engaged` | ✓ | "A handle. Of course. Roll the keys around G, clockwise. Yes, you are the download speed. Budget cuts." |
| `av_slipping` | ✓ | "Stop cranking and it slips back. A bit like your career." |
| `av_wrong_way` | ✓ | "That's un-downloading. You're sending it back to the hamster." |
| `av_dial_again` | ✓ | "It's already a crank. Clicking won't make it more of a crank." |
| `av_halfway` | ✓ | "Halfway. ZappWare thanks you for powering its servers personally." |
| `av_done` | ✓ | "Download complete. It's scanning now. It looks… hungry." |
| `lights_out_3` (rewrite) | ✓ | "The antivirus found a hundred and twenty threats. All of them light bulbs. It quarantined the lot. The office is now virus-free, and light-free. On the bright side, sorry, the server room hasn't moved." |
| `controls_shift` | ✓ | "While you were groping around in the dark, someone nudged your hands one key to the right. E-S-D-F. The professional's choice. You're welcome." |
| `controls_shift_w` | ✓ | "W? We don't do W any more. Keep up." |

Keep `av_done` short: the blackout's scene change cuts whatever is still playing.

## 5. Sounds + credits

- **Crank click:** `scratchpad/audio2/out/screw_ratchet_1_xxqmanxx.wav` (0.36 s, one ratchet burst) and `screw_ratchet_2_xxqmanxx.wav` (0.83 s, two bursts; cut its second burst as a 2nd variant), both cut from Freesound **147018 "Socket Wrench" by xxqmanxx, CC0** (1.14–1.50 s and 2.22–3.05 s of the original). Copy to `game/assets/audio/sfx/freesound/crank_ratchet_1_xxqmanxx.wav` / `_2_` → `crank_ratchet.tres` (AudioStreamRandomizer). A socket-wrench ratchet per 60° step reads as a hand crank; plus the existing `foley_creak_1.wav` once per turn for the wooden crank feel. **Listen first.** If it doesn't sound like a crank: Freesound search, filter `license:"Creative Commons 0"`, duration < 4 s, queries "hand crank", "crank ratchet", "winding crank", "music box wind up", "fishing reel crank", "jack in the box crank"; cut one tooth/turn into a ~0.2 s one-shot.
- **400 Sounds Pack** (unaltered, copy from `scratchpad/sounds400/extracted/`): `Other/slide_and_click.wav` (engage the crank), `UI/synth_process_complete.wav` (100 %), `Machines/hydraulic_down.wav` (optional slip-back sigh; listen). Already in the game: `pop_2`, `whoosh_1` (AppWindow), `wobble.wav`, `foley_creak_1.wav`, `power_down.wav` (blackout).
- Credits: Freesound row in `game/assets/audio/CREDITS.md` (title, URL https://freesound.org/people/xxqmanxx/sounds/147018/, author, cuts, use) + the summary line; new 400 Sounds Pack files in its list; `game/CREDITS.md` line. Fonts already credited (Tinos, Comic Relief, Comic Shanns Mono, Comic Neue).

## 6. Order of work

1. `antivirus_offer` → registry → driver. 2. `crank_dial.gd` + `download_bar.gd` → screenshot the layout against the reference before any logic. 3. `antivirus_download` logic + sounds. 4. `THIRD_VISIT`, rewrite `lights_out_3`, new cues. 5. `Controls` + story wiring + F8. 6. Docs: plan.md engineering log entry, progress.md "Visit 3" `[x]` + "After the third blackout: ESDF" `[x]`, TODO-script list, credits.

## 7. Test plan

- **Static:** `/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --quit` after each step (no parse/load errors; imports the new sounds).
- **Driver harness** (as visit 2): `rsync -a --delete game/ $SP/v3test/`, autoload `_drv="*res://drv_<name>.gd"` in the copy's `project.godot` only, run windowed (`Godot --path $SP/v3test`), log to `$SP/v3test/run_<name>.log`, screenshots to `$SP/shots_v3/`. Reuse visit 2's `click`/`drag`/`shot` helpers, plus `ring(code)` = `InputEventKey` with `physical_keycode = code`, `pressed` true then false 40 ms later, via `Input.parse_input_event`, and `roll(dir, steps, gap = 0.1)` stepping through `TwistInput.RING` (clockwise = index +1). Start each game alone with `Computer.queue([&"<id>"], false)` + `change_scene_to_file(Computer.SCENE)`.
  - **drv_offer:** shot after pop-in; assert the AppWindow X is hidden; click the ghost X rect → assert the shake + `av_no_x` subtitle, click again → `av_no_x_again`; press Esc → refused; press letters → `computer.buffer` unchanged; drag the window 900 px right → it springs back; click Later → text "Remind me NOW", click again → `completed`. 2nd run: click DOWNLOAD → `completed`; 3rd run idle 13 s → `av_offer_nudge`.
  - **drv_download:** shot at WAITING; roll keys → percent stays 0 and `av_dial_nudge`; click the bar → `av_bar_click`; click the dial → engaged, hint visible, shot; `roll(+1, 9)` → percent ≈ 30 (3.33 per step), shot; wait 2 s → percent back to 25 (checkpoint), shot mid-slip; `roll(-1, 3)` → decreases, `av_wrong_way`; roll on to 100 → DONE shot (red status, self-spinning dial), `completed` within `finish_hold` + 0.5 s; assert `computer.buffer` unchanged throughout (keys didn't type).
  - **drv_visit3 (end to end):** `Story._go_to(Story.Step.COMPUTER_3)`, change to `Computer.SCENE`, play both. Assert step SWITCH_3, `GameState.power_on == false`, office loaded dark, subtitle `lights_out_3` then `controls_shift`, `Controls.shifted`, `InputMap.action_get_events(&"move_forward")[0].physical_keycode == KEY_E`; hold physical E 0.5 s → the player moved forward; press W → `controls_shift_w`; the HUD prompt at the power switch says "Press C". Shots: blackout flicker over the download screen, the dark office with the subtitle. F7 back-check: `_go_to(COMPUTER_3)` un-shifts.
  - Look at every screenshot and judge whether it reads like the reference and looks comic/readable (plan.md rule); fix before reporting.
- **Manual (user):** crank pace (15–20 s target, `rotations_to_finish`), slip-back harshness, ratchet/creak volumes, whether the ghost X is findable and funny.

## 8. Risks / open questions

- **Key routing** (§2 "Keys"): the most likely bug. If the ring is left on `listen = true`, the crank does nothing and the letters type into the hidden document.
- **TwistHint on a dark background:** check contrast (its keys are dark grey). Raise `key_color` alpha/lightness on this instance if needed. `intro_cue = &""` so `twist_tutorial` doesn't cut `av_engaged` (our line teaches it; the screwdriver already played the tutorial in a normal run).
- **Clockwise vs the screwdriver's anticlockwise:** deliberate (winding = clockwise), and the hint's arrow/demo teaches it. If playtesters fight it, accept both directions (`abs(delta)`) and drop `av_wrong_way`.
- **Overlap with visit 2's `software_update`** (also a progress bar with rollback): keep the gags different (slip-back to checkpoint vs rollback/missing 1 %), separate bar classes (`DownloadBar` vs `UpdateBar`). If visit 2 is cut, the 99 % gag could move here.
- **Serif-ish percentage font:** only Regular subsets are bundled; embolden via FontVariation. Judge in the screenshot.
- **Ghost-X clicks:** `AppWindow` emits `gui_input` for title-bar presses (it handles drag there too). A click on the ghost both starts a drag and is refused, which is fine.
- **Narrator overlap:** many `once` lines in ~40 s; gate optional ones (`halfway`, `bar_click`, `dial_again`, `no_x_again`) on `not Narrator.is_speaking()`. `av_done` gets cut by the scene change if it's long.
- **ESDF:** the F clash for SWITCH_3's twist games (§3); web layout mapping for the "Press C" prompt (`esdf_and_web.md`). The project's WASD events are logical `keycode`, the shifted ones physical: fine on QWERTY, consider the optional physical cleanup.
- **Open:** keep the name "ZappWare"? Should the antivirus also lock the Power button during the visit ("disabled for your protection")? It's cheap (`$Screen/PowerButton.disabled`) but needs a small public setter on `Computer`.

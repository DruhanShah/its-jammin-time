# Plan: ESDF control shift + Web (itch.io) export test

Status: planning only (2026-10-06). Nothing below is implemented yet.

---

## 1. ESDF shift after the third blackout

### When
The third blackout is `Story.Step.SWITCH_3`. Flow today: visit 3 beaten → `Story._on_computer_queue_finished()` → `_go_to(SWITCH_3)` → `Computer.blackout()` → `GameState.set_power(false)` → arrival cue `lights_out_3` → the office loads dark and `StoryStage` plays it.

- **Remap:** in `Story._go_to()`, derive it from the step, the same way `_sync_unlocks()` works: `Controls.set_shifted(step >= Step.SWITCH_3)`. The player is at the computer at that moment (they're typing, not moving), so the change is invisible until the dark office loads. Deriving it from the step means debug skips (F7), scene reloads and a future "new game" (back to `INTRO`) stay correct with no extra state.
- **Narration:** play it right after `lights_out_3`, not over it (`Narrator.play` cuts off the current line). Story listens for `Narrator.line_finished(&"lights_out_3")` and plays `controls_shift` (`once = true`). As a fallback, in case `lights_out_3` was cut off or skipped: the first time the player presses W or A (by physical key) while shifted, play `controls_shift` if it hasn't played yet, otherwise `controls_shift_w` (once).
- Other option, if the user meant "after the third blackout is *fixed*": use `step >= FREE_ROAM` instead. It's a one-line change, so check with the user.

### What moves (one key to the right, by physical position)
| Action | Now | Shifted |
|---|---|---|
| move_forward | W | **E** |
| move_left | A | **S** |
| move_back | S | **D** |
| move_right | D | **F** |
| interact | X | **C** (keeps the "one to the right" rule; the HUD prompt updates by itself) |
| touch (LMB), ui_* (Esc/Enter/arrows), F5–F7 debug | — | unchanged |

**Clashes**
- **F is both `move_right` and a twist-ring key** (ring = T Y H B V F, read by `physical_keycode` in `TwistInput`; the ring is *not* remapped, since it's built around G). SWITCH_3's switch games (`kaleidoscope`, `candle`) are exactly the twist games that come after the shift. Movement is *polled* (`Input.get_vector` in `player.gd`), so `set_input_as_handled()` can't block it. The rule: every twist game either runs in its own close-up scene with no Player (like `screwdriver`), or sets a new `Player.movement_locked` flag while its TwistInput listens. Otherwise rolling the ring makes you strafe right.
- E, S, D and C aren't in the ring. W and A now do nothing (that's the gag). D used to mean right and now means back.
- Computer minigames read typed text, not these actions, so they're unaffected.
- Optional gag: the narrator remarks that the twist keys "didn't move, they're load-bearing".

### How (pseudocode): new `game/core/input/controls.gd`
```gdscript
class_name Controls
## Runtime control remaps. InputMap is global, so it survives scene changes by itself.
const SHIFTED := {&"move_forward": KEY_E, &"move_left": KEY_S, &"move_back": KEY_D,
		&"move_right": KEY_F, &"interact": KEY_C}
static var shifted := false

static func set_shifted(on: bool) -> void:
	if on == shifted:
		return
	shifted = on
	InputMap.load_from_project_settings()   # back to WASD + X (the project defaults)
	if on:
		for action: StringName in SHIFTED:
			InputMap.action_erase_events(action)
			var ev := InputEventKey.new()
			ev.physical_keycode = SHIFTED[action]   # position, not letter: works on AZERTY etc.
			InputMap.action_add_event(action, ev)
	for action: StringName in SHIFTED:
		Input.action_release(action)   # a key held during the swap would otherwise stay "pressed"
```
In `story.gd`:
```gdscript
func _go_to(new_step):  ...; _sync_unlocks(); _sync_controls(new_step); step_changed.emit(...)
func _sync_controls(s):
	var was := Controls.shifted
	Controls.set_shifted(s >= Step.SWITCH_3)
	_controls_cue_pending = Controls.shifted and not was
func _ready(): ...; Narrator.line_finished.connect(_on_line_finished)
func _on_line_finished(id):
	if id == &"lights_out_3" and _controls_cue_pending:
		_controls_cue_pending = false; Narrator.play(&"controls_shift")
func _unhandled_input(e):  # fallback jab
	if Controls.shifted and e is InputEventKey and e.pressed and not e.echo \
			and e.physical_keycode in [KEY_W, KEY_A]:
		Narrator.play(&"controls_shift" if _controls_cue_pending else &"controls_shift_w")
		_controls_cue_pending = false
```
- **Persistence:** you don't need `GameState`. InputMap lives for the whole process, and the remap is re-derived from `GameState.story_step` on every `_go_to`. Nothing is saved to disk, so restarting the game always starts on WASD. If a save system is added later, it still derives from the step.
- **HUD:** `PlayerHud.key_name()` already converts a `physical_keycode`-only event through `DisplayServer.keyboard_get_keycode_from_physical`, so the prompt reads "Press C to …" with no extra code. Check this on web too, where the layout mapping may return the key unchanged. "C" is still correct there.
- **Revert/debug:** F7 debug skip goes through `_go_to`, so it's handled. Add an optional `debug_toggle_controls` (F8, debug builds only) that calls `Controls.set_shifted(not Controls.shifted)`. A future "new game" just calls `_go_to(INTRO)`.
- **Optional cleanup:** the project's WASD/X events use logical `keycode`. Switching them to `physical_keycode` makes "one to the right" consistent on every layout. It's a small `project.godot` edit made through the editor's Input Map.
- **Placeholder narration** (subtitle-only `NarratorCue`s in `game/narration/`, add to the TODO-script list in `docs/plan.md`):
  - `controls_shift`: "While you were groping around in the dark, someone nudged your hands one key to the right. E-S-D-F. The professional's choice. You're welcome."
  - `controls_shift_w`: "W? We don't do W any more. Keep up."

---

## 2. Web export test plan (itch.io, HTML5)

### Current state (checked)
- The Web preset exists: `variant/thread_support=false`, no extensions, desktop VRAM compression only, `canvas_resize_policy=2` (adaptive), `focus_canvas_on_start=true`, same addon exclude filter as macOS. Its default `export_path` is `export/web/index.html` (gitignored), but **always pass a scratch path**.
- **No export templates are installed**: `~/Library/Application Support/Godot/export_templates/` is empty. The editor binary is `/Applications/Godot.app/Contents/MacOS/Godot` (4.7.2.stable.official.ed1daf0bf). `--help` has **no `--install-export-templates` flag**; the only template-related CLI option is `--install-android-build-template`.
- Office environment: `ssao_enabled`, `glow_enabled` and `fog_enabled` are all on. The Compatibility renderer doesn't implement SSAO (it's ignored on desktop too, so it's effectively dead weight; confirm by toggling it). Glow (multi-pass blur) and depth fog do run in Compatibility.
- Audio: `audio/driver/enable_input=true`. `audio/general/default_playback_type.web` isn't set, so it's **Sample** (the default). The mic player forces `PLAYBACK_TYPE_STREAM` (`password_scream.gd:278`), which the capture bus needs. Music ducking changes the player's volume, so it works in Sample mode.
- `display/window/dpi/allow_hidpi` defaults to on. On a Retina Mac in fullscreen, the canvas renders at 2× DPR (about 2880×1800), which is the biggest fill-rate risk together with ~120 spot lights and glow.

### Step 0: install the 4.7.2 templates (once, outside the repo)
Either use the editor (Editor → Manage Export Templates → Download and Install, or Install from File with a `.tpz`), or do it by hand:
```sh
V=4.7.2-stable; D="$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
cd "$SCRATCH" && curl -LO https://github.com/godotengine/godot/releases/download/$V/Godot_v${V}_export_templates.tpz
unzip -q Godot_v${V}_export_templates.tpz && mkdir -p "$D" && mv templates/* "$D"/
ls "$D" | grep web_nothreads   # need web_nothreads_release.zip and web_nothreads_debug.zip
```
The `.tpz` is a zip of `templates/` and is about 1 GB. Pulling only the two `web_nothreads_*.zip` files plus `version.txt` into `$D` also works.

### Step 1: export to scratch (never into the repo)
```sh
G=/Applications/Godot.app/Contents/MacOS/Godot; P=/Users/vishesh/its-jammin-time/game
OUT="$SCRATCH/web_rel"; mkdir -p "$OUT" "$SCRATCH/web_dbg"
$G --headless --path "$P" --import                    # only if .godot/ is stale/fresh clone
$G --headless --path "$P" --export-release "Web" "$OUT/index.html"
$G --headless --path "$P" --export-debug   "Web" "$SCRATCH/web_dbg/index.html"   # for script errors in console
du -sh "$OUT"/*; (cd "$OUT" && zip -qr "$SCRATCH/itch_web.zip" .) ; du -h "$SCRATCH/itch_web.zip"
```
Afterwards, run `git status` in the repo and confirm it's clean. Only `game/.godot/` (ignored) may change. Check the size: expect a wasm of about 35–45 MB plus a pck of about 20–30 MB. That's far under itch's HTML5 limits (verify the current numbers at itch.io/docs/creators/html5: a ZIP with `index.html` at the root, ≤1000 files, ≤200 MB per file). Load time is the real cost, so record the cold-load time.

### Step 2: serve locally
A non-threaded build needs no COOP/COEP headers. Python 3.13 already maps `.wasm` → `application/wasm`. Use `localhost`: it counts as a secure context, so `getUserMedia` works.
```sh
cd "$SCRATCH/web_rel" && python3 -m http.server 8060 --bind 127.0.0.1
```
Run it as a background Bash task. Never open the file via `file://`.

### Step 3: browser checks (orchestrator, claude-in-chrome)
Load the tools in one ToolSearch call (`tabs_context_mcp, tabs_create_mcp, navigate, computer, read_page, read_console_messages, javascript_tool, gif_creator, tabs_close_mcp`), open a **new tab**, and go to `http://127.0.0.1:8060/`.

1. **Boot:** `read_console_messages` should show no errors. Note the time until the first frame. Run `javascript_tool`: `const gl=document.createElement('canvas').getContext('webgl2');const x=gl.getExtension('WEBGL_debug_renderer_info');[gl.getParameter(x.UNMASKED_RENDERER_WEBGL), devicePixelRatio, document.querySelector('canvas').width]` to record the GPU, the DPR and the canvas backing size.
2. **Click to start:** click the canvas. That user gesture resumes the AudioContext and focuses the canvas. Story music, `story_intro` and the computer should start, and the mic login (visit 1) should open.
3. **Mic:** Chrome shows a permission bubble. **The extension can't click browser permission UI**, so either the user clicks Allow, or you pre-allow `http://127.0.0.1:8060` in chrome://settings/content/microphone. Check: allowed = a live waveform; denied = the fake waveform and no console exceptions; the login still advances after 5 tries.
4. **FPS:** run this rAF counter in `javascript_tool` (Godot's loop runs on rAF, so it tracks game FPS): `await new Promise(r=>{let n=0,t=performance.now();(function f(){n++;performance.now()-t<5000?requestAnimationFrame(f):r(n/5)})()})`. Take it at: the desk; a doorway looking through 2–3 rooms; C1 (flickering amber lights); lights-out (emergency look); and fullscreen. For more detail, use the debug overlay proposed below (`?perf` prints `Engine.get_frames_per_second()` and draw calls to the console every 2 s, read with `read_console_messages`).
5. **Pointer lock:** `player.gd` calls `Input.mouse_mode = CAPTURED` in `_ready()` with no gesture. That will most likely fail on web (the browser needs transient user activation), so the first office load may not lock. The existing "click → recapture" branch covers it, but only if Godot's `mouse_mode` reports VISIBLE after a failed or exited lock. Test: (a) the office load after the computer blackout, then click to look; (b) press Esc. The browser releases the lock, so check that Godot's mode follows and a click relocks. Chrome refuses a relock for about 1 s after an Esc exit, so allow for that. (c) Leaving a minigame (fade) returns to a captured mouse. If (b) gets stuck, the fix is: on web, in `_unhandled_input`, treat any mouse click as "recapture" when `DisplayServer.mouse_get_mode() != CAPTURED`. CDP mouse moves may not produce `movementX`, so **mouse look itself needs a human test**; the agent checks the console plus `document.pointerLockElement` via JS.
6. **Keyboard:** WASD/X, F5–F7 in the **debug** build (make sure F5 doesn't reload the page, so Godot must call `preventDefault`), Esc in minigames, typing in the computer minigames, and the twist ring (B-H-Y-T-F-V) in the screwdriver.
7. **Fullscreen:** test from Godot if a toggle exists; otherwise use the itch fullscreen button (step 5). With adaptive resize, the canvas should fill the screen without distortion. Record FPS in fullscreen.
8. **Physics/Jolt:** push chairs between rooms and listen for the bump sounds. Jolt is a built-in module and runs single-threaded in the no-threads template. If it fails, the fallback is `physics/3d/physics_engine.web="GodotPhysics3D"`.
9. **Audio:** footsteps (`AudioStreamRandomizer`; check that it plays in Sample mode), narrator ducking, SFX on scene changes, and no crackle in the Stream-mode mic player. On a no-threads build, Stream mixing runs on the main thread and crackles when frames run long.
10. Record a GIF of the full loop (`gif_creator`) and close the tab.

### Step 4: performance risks and mitigations (try in this order, all web-only)
Use **feature-tag overrides** in `project.godot` (`setting.web=value`) and `OS.has_feature("web")` in `lighting.gd`, so desktop stays untouched:
1. `display/window/dpi/allow_hidpi.web=false`: renders at CSS pixels and is the biggest win on Retina.
2. Turn off glow on web in `lighting.gd` (`env.glow_enabled = false`; the env is already duplicated per load). Turn off `ssao_enabled` everywhere, since it does nothing in Compatibility. Keep fog, which is cheap.
3. Lights: enable `distance_fade_enabled` on `CeilingLight` (begin about 18 m, length 4 m) so lights from far rooms are dropped. If that's not enough, set `rendering/limits/opengl/max_lights_per_object.web=8`, or on web hide every other light per room and raise energy. Recheck the lights-out look.
4. `rendering/scaling_3d/scale.web=0.75` (bilinear; check that Compatibility honours it in 4.7).
5. Physics catch-up: if FPS drops below 60, `physics/common/max_physics_steps_per_frame.web=4` stops the slowdown from feeding on itself.
6. Shader-compile hitches (WebGL compiles variants the first time it sees them, e.g. on the first lights-out): show both looks for one frame behind the opening fade if this turns out to be noticeable.

Targets: 60 FPS at 1280×720 embed and ≥30 FPS in fullscreen on an integrated-GPU Mac. Measure baseline → apply 1–2 → measure again.

**Proposed debug overlay** (small, works in release builds): an autoload `DebugOverlay`, a CanvasLayer with a Label for FPS, `RenderingServer.get_rendering_info(RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)` and the current room. It toggles with a new `debug_fps` action on F3, or turns on and also `print`s every 2 s when `JavaScriptBridge.eval("location.search")` contains `perf`.

### Step 5: itch.io page settings
- Kind of project: **HTML**. Upload `itch_web.zip` with "This file will be played in the browser" ticked (or `butler push itch_web.zip <user>/<game>:html5`). Keep the page **Draft/Restricted** until it's tested.
- Viewport **1280×720** (16:9; the project stretches with `canvas_items`/`expand`). **Fullscreen button: on.** **Automatically start on page load: off.** Itch's "Run game" click is the gesture that unlocks audio and mic and focuses the iframe. **Mobile friendly: off** (keyboard + mouse only). **SharedArrayBuffer support: off** (no-threads build; turning it on adds COOP/COEP isolation for nothing). Scrollbars: off.
- Repeat the step 3 checks on the itch draft URL. Itch's iframe allows `microphone` and was already verified. Also check that keys reach the game only after clicking inside the iframe, that Esc exits pointer lock but not fullscreen, and that the arrow keys and Space don't scroll the itch page.

---

## As built (§1 ESDF shift)

- `game/core/input/controls.gd` (`class_name Controls`, static): as the pseudocode (physical keycodes E/S/D/F + C, revert with `InputMap.load_from_project_settings()`, `Input.action_release` on every swap).
- `core/story.gd`: `CONTROLS_SHIFT_STEP = SWITCH_3` (the third blackout, as planned; change it to `FREE_ROAM` if the shift should come after the fix). `_sync_controls()` runs in every `_go_to()`. `Narrator.line_finished(lights_out_3)` → `controls_shift` (deferred, and only if the narrator is idle, since an interrupt also emits `line_finished`). Fallback/jab: W or A (physical) while shifted, only while walking (mouse captured, so typing on the computer never triggers it) and only when the narrator is idle → `controls_shift` if still pending, else `controls_shift_w` (once).
- **F8 debug toggle** is handled in code (`Story._unhandled_input`, physical F8, debug builds only), so `project.godot` is untouched.
- Texts: `controls_shift` "While the lights were out, someone nudged your hands one key to the right. E, S, D, F. The professional's choice. You're welcome."; `controls_shift_w` "W? We don't do W any more. Keep up."
- **Not done:** the `Player.movement_locked` flag for the twist games (F is both `move_right` and a twist-ring key); whoever builds `kaleidoscope`/`candle` must add it or use a close-up scene. The project's WASD/X stay logical keycodes (no `project.godot` edit).
- **Verified** (windowed driver after visit 3's blackout): step SWITCH_3, `Controls.shifted`, `lights_out_3` then `controls_shift`; holding W moves 0 m, E moves 1.5 m, S strafes; A → `controls_shift_w`; aiming at the desk computer shows "Press C to use the computer"; F8 → WASD/X (prompt key "X"), F8 again → ESDF. No errors or warnings.

# Plan: SWITCH_3 — Kaleidoscope (obstacle) + Candle (restore)

Third blackout. The server room (`Rooms/C1` node) still stands at A3's spot, switch on the **west** wall (C1-local (−5.85, 0, 1) after `StoryStage._swap_rooms()`). `Story.SWITCH_GAMES[SWITCH_3] = [kaleidoscope, candle]` already exists; this plan fills both in.

## 0. Shared decisions

- **Kaleidoscope = hybrid.** Binoculars pickup + looking at the painting happen **in the office** (scope = full-screen overlay, player frozen, no scene change). Typing the password is a **close-up 2D keypad scene** opened by the power switch. Reason: the painting must be seen on the wall next to the switch; the keypad fits the existing "switch opens a scene" framework, no `scene = ""` special case.
- **Candle = 3D close-up** scene like `screwdriver/` (own camera, lights, HUD), chained automatically after the keypad via `Story.next_switch_scene()`.
- **No screen-texture read on the critical path.** The scope view samples the painting's *source texture* directly (same shader as the painting on the wall), so it is exact, cheap and WebGL2-safe. `hint_screen_texture` is used only by the optional pickup gag (§1.8).
- New per-step state in `GameState` (reset in `Story._go_to()` together with `switch_progress`):
  `scope_password := ""`, `scope_target := 0` (key steps), `has_scope := false`, `scope_solved := false`.
- Player freeze: add `var frozen := false` to `core/player/player.gd`; when true skip mouse look, movement input, interact ray/prompt, head bob and the Esc mouse-release branch (`_unhandled_input`, `_physics_process`, `_process`). HUD prompt hidden while frozen.

## 1. Kaleidoscope

### 1.1 Files
```
game/minigames/switch/kaleidoscope/
  kaleidoscope.gd          # class_name Kaleidoscope: consts + static ensure()/error helpers
  kaleido.gdshaderinc      # wedge maths shared by both shaders
  painting_kaleido.gdshader  # spatial, on the wall painting (err = -target)
  scope_kaleido.gdshader     # canvas_item, full-screen scope view
  painting_source.tscn     # SubViewport 512x512: shards + password (the texture both sample)
  twist_me_painting.tscn/.gd  # wall prop (Painting.fbx + source + "TWIST ME" + Interactable)
  binoculars.tscn/.gd      # pickup on the C1 ControlDesk
  scope_view.tscn/.gd      # CanvasLayer overlay: twist, feedback, solve
  keypad.tscn/.gd          # close-up keypad (switch scene)
game/assets/models/binoculars/binoculars.glb + CREDITS.md
```
`SwitchGames.GAMES[&"kaleidoscope"] = {verb = "type the password", scene = "res://minigames/switch/kaleidoscope/keypad.tscn"}`.

### 1.2 Password + target (`kaleidoscope.gd`)
```gdscript
const WORDS := ["SPIRAL", "PRETZEL", "TORNADO", "NOODLE", "TWIRL", "DIZZY", "SWIRL", "LOOPY", "WHIRL", "CURLY"]
const STEP_DEG := 15.0        # scope barrel turn per ring-key step (TwistInput step = 60°, GEAR 0.25)
const WEDGES := 6
const MULT := [1.0, -2.0, 3.0, -1.0, 2.0, -3.0]   # per-wedge rotation multiplier (mirror in shader)
static func ensure() -> void:
    if GameState.scope_password.is_empty():
        GameState.scope_password = WORDS.pick_random()
        GameState.scope_target = randi_range(9, 20)   # 135°..300°: 1.5–3.3 laps of the ring
static func error_steps(steps: int) -> int: return steps - GameState.scope_target
```
Called from the painting's `_ready()` and the keypad's `_ready()`. Password never equals "TWISTME" (gag reserved for the keypad).

### 1.3 Painting source (`painting_source.tscn`)
```
PaintingSource (SubViewport, size 512x512, transparent_bg false, render_target_update_mode ONCE, disable_3d)
 ├ Bg (ColorRect, warm off-white)
 ├ Shards (Node2D, script draws 14 random Polygon2D triangles, seeded from the password hash, palette = existing painting colours)
 └ Word (Label, full rect, centred, Comic Relief Bold ~110 px (autoshrink to fit 7 letters), black, outline 12 px white)
```
Script: `func setup(word)`: set text, then `render_target_update_mode = UPDATE_ONCE` again next frame. Texture handed out by code (`source.get_texture()`), never as a ViewportTexture path across scenes.

### 1.4 Wedge shader maths (`kaleido.gdshaderinc`)
Same function for wall and scope, so the wall shows exactly the scope's "angle 0" frame.
```glsl
const float MULT[6] = float[](1.0, -2.0, 3.0, -1.0, 2.0, -3.0);
// p: centred, aspect-corrected, |p|<=1 covers the canvas. err: radians (scope - target). Returns source uv.
vec2 kaleido_uv(vec2 p, float err, float mirror) {
    float a = atan(p.y, p.x), r = length(p), w = TAU / 6.0;
    int i = int(floor((a + PI) / w)) % 6;
    float local = mod(a + PI, w);                      // 0..w inside the wedge
    if (mirror > 0.5 && (i & 1) == 1) local = w - local; // real kaleidoscope flip, odd wedges
    float a2 = (float(i) * w - PI) + local + err * MULT[i];
    return vec2(cos(a2), sin(a2)) * r * 0.5 + 0.5;
}
float seam(vec2 p) {  // distance to the nearest wedge border, for seam lines
    float w = TAU / 6.0; float local = mod(atan(p.y, p.x) + PI, w);
    return length(p) * sin(min(local, w - local));
}
```
Fragment (both shaders):
```glsl
float m = smoothstep(0.0, 0.35, abs(err));            // 0 aligned .. 1 far (~20°)
vec3 clean = texture(source, kaleido_uv(p, err, 0.0)).rgb;
vec3 flip  = texture(source, kaleido_uv(p, err, 1.0)).rgb;
vec3 col = mix(clean, flip, 0.5 * m);                  // mirror ghosting fades out as it aligns
float s = 1.0 - smoothstep(0.004, 0.012, seam(p));
col = mix(col, seam_color.rgb, s * m);                 // seams: black far, gold "almost", gone when aligned
col += glow * 0.6 * (1.0 - smoothstep(0.0, 0.7, length(p)));  // solve flash
```
Why it works: each wedge shows the painting rotated by `err × MULT[i]`; at `err = 0` every wedge shows the unrotated image, so the six pieces join into the readable word. One step off (15°) shifts wedges by 15–45°: letters partly line up = natural "almost". Wall material: `err = -target_rad`, `mirror` term at full (m = 1) → abstract shard mandala. Scope: `err = (shown_steps - target) × 15°`, eased.
`painting_kaleido.gdshader`: `shader_type spatial;` albedo = col, roughness 0.8, uniform `sampler2D source : source_color, filter_linear, repeat_disable`; p from `UV * 2.0 - 1.0` (canvas is roughly square; pass `aspect` uniform if not). `scope_kaleido.gdshader`: `shader_type canvas_item;` p from `(UV - 0.5) * vec2(aspect, 1) * 2.0 / zoom`, circular mask `length(p) < 1` with a dark brass rim; outside = black.

### 1.5 Wall painting (`twist_me_painting.tscn`, under `Rooms/C1/Furniture/TwistMePainting`)
```
TwistMePainting (Node3D, twist_me_painting.gd)  # transform basis like PowerSwitch, C1-local ≈ (5.88, 1.7, −1.7)
 ├ Frame (Painting.fbx instance; surface 1 override = ShaderMaterial painting_kaleido)
 ├ Source (painting_source.tscn)
 ├ TwistMe (Label3D "TWIST ME", Comic Relief Bold, yellow + black outline, rot z −8°, on the canvas, no shading)
 └ Interactable (box over the canvas; verb set in code)
```
- Add `^"Furniture/TwistMePainting"` to `StoryStage.MIRRORED_TO_WEST_WALL`, so it follows the switch to the west wall. Verify clearance from `RackS10` (4.96, 0, 3.3) and the aisle in an editor screenshot; fallback z = 3.0 or above the switch (y 2.2, below the clock at 2.9).
- The painting always hangs there (foreshadowing from SWITCH_1 on). Interactable `enabled` only when `Story.switch_game() == &"kaleidoscope"`; verb: "look through the binoculars" if `has_scope` else "twist the painting".
- `interacted`: no scope → `Narrator.play(&"twist_me_bare_hands")` (+ `hands.touch()`); with scope → instance `scope_view.tscn` into the current scene, `scope.open(source.get_texture())`.

### 1.6 Binoculars (`binoculars.tscn`, on `Rooms/C1/Furniture/ControlDesk` top, C1-local ≈ (−3.6, desk top, 7.45))
`Binoculars (Node3D)` → `Model (binoculars.glb, scaled to ~0.18 m)`, `StaticBody3D + BoxShape3D`, `Interactable verb "pick up the binoculars"`. `_ready`/`Story.switch_game_changed`: `visible = enabled = (switch_game() == &"kaleidoscope" and not GameState.has_scope)`. On interact: `GameState.has_scope = true`, hide, `Narrator.play(&"scope_pickup")`. (Desk top height: measure in editor; `ws_*` desks use 0.949.)

### 1.7 Scope view (`scope_view.tscn`, CanvasLayer layer 10, group `scope_view`)
```
ScopeView (CanvasLayer, scope_view.gd)
 ├ Dim (ColorRect black, full rect)
 ├ View (ColorRect full rect, ShaderMaterial scope_kaleido; uniforms source, err, glow, aspect, seam_color)
 ├ Barrel (Control, _draw(): brass ring with tick marks, rotation = shown angle → sells the twist)
 ├ TwistInput
 ├ Hint (twist_hint.tscn, bottom-right; twist = ../TwistInput)
 ├ Feedback (Label, Comic Relief Bold, centre-bottom: "Almost!" / password reveal)
 └ Exit (Label "Esc: lower the binoculars")
```
Logic (pseudocode):
```gdscript
var steps := 0        # scope barrel steps (signed, from TwistInput.twisted delta/60)
var shown := 0.0      # eased, in steps
var still := 0.0      # seconds aligned without moving
func open(tex): Kaleidoscope.ensure(); player.frozen = true; View.material.set("source", tex)
    if GameState.scope_solved: steps = target (opens aligned, shows the word); else Narrator.play(&"scope_open")
    Hint.arrow_direction = 1
func _on_twisted(d): if solved: return
    steps += int(d / 60.0); still = 0
    var e := Kaleidoscope.error_steps(steps)
    tick sound pitch_scale = 1.0 + 0.6 * (1.0 - clamp(abs(e) / 6.0, 0, 1))   # rises as it closes in
    Hint.arrow_direction = 1 if e < 0 else (-1 if e > 0 else Hint.arrow_direction) # "Other way!" on overshoot
    Feedback: abs(e) <= 2 and e != 0 -> pop "Almost!" (scale tween), seam_color gold; else hide, seam black
    if abs(e) == 1 and not _almost_said: Narrator.play(&"scope_almost")  (cue is `once`)
func _process(dt): shown = lerp(shown, steps, 1 - exp(-10 * dt)); err = deg_to_rad((shown - target) * 15)
    if not solved and error_steps(steps) == 0: still += dt; if still >= 0.6: _solve()
func _solve(): solved = true; GameState.scope_solved = true; click sfx (slide_and_click);
    tween glow 0 -> 1 -> 0 (0.5 s); Feedback.text = "PASSWORD: %s" % word; Hint.hide(); Narrator.play(&"scope_solved")
func ui_cancel: player.frozen = false; queue_free()
```
"Almost" feedback is layered: wedges visibly nearly joining (shader), gold seams + "Almost!" label at ±1–2 steps, rising tick pitch, TwistHint arrow flipping on overshoot. `StoryStage._check_off_path` skips while a node is in group `scope_view`.

### 1.8 Optional gag: first raise twists the world
On pickup, raise the scope for ~2.5 s *at whatever you're looking at* with a canvas shader that samples `hint_screen_texture` through `kaleido_uv(p, TIME * 0.6, 1.0)` (the world spins in mirrored wedges), then lower it; narrator `scope_pickup` explains. Compatibility supports `hint_screen_texture` in canvas_item shaders (back-buffer copy of the 3D output); verify in the Web export, else drop it (narration alone carries the joke). Hide the HUD crosshair during it.

### 1.9 Keypad (`keypad.tscn`, close-up 2D, opened by the switch)
```
Keypad (Control full rect, keypad.gd)  # ComicCursor.apply(), mouse visible
 ├ Bg (ColorRect dark + halftone.gdshader radial)
 └ Window (AppWindow "SWITCHBOARD SECURITY 3000", auto_close false -> X = leave)
    └ VBox
       ├ Lcd (PanelContainer green-black) → Text (Label, Comic Shanns Mono 48, "_" blink, max 9 chars)
       ├ Keys (GridContainer 7 cols: A–Z buttons + ⌫ + ENTER, comic button theme)
       └ Status (Label: "ENTER PASSWORD" / "ACCESS DENIED" / "ACCESS GRANTED")
```
Input: buttons or physical keys (`InputEventKey.unicode` A–Z → upper, Backspace, Enter/KP Enter); Esc → `Transition.change_scene(Story.OFFICE)`.
`_submit(t)`: `t == GameState.scope_password` → Status green, `ComicBurst.spawn(self, lcd centre, "CLICK!")`, brass_positive_long sfx, `Narrator.play(&"keypad_right")`, wait line (max 8 s), `Story.switch_game_done(&"kaleidoscope")`, `Transition.change_scene(Story.next_switch_scene())` (= candle). Else `Window.shake()`, buzzer, LCD flashes red, cue: `t == "TWISTME"` → `keypad_twist_me`; `t == GameState.password.to_upper()` → `keypad_old_password`; not `scope_solved` → `keypad_no_password` (once, then falls through); else alternate `keypad_wrong_1/2`.

## 2. Candle (`game/minigames/switch/candle/`)

Files: `candle.tscn/.gd`, `strand_twist.gdshader`, `flame_flicker.gd` (tiny), `game/assets/models/candle/candle.glb` + `CREDITS.md`. `SwitchGames.GAMES[&"candle"] = {verb = "light the candle", scene = "res://minigames/switch/candle/candle.tscn"}`.

Model: **Nick Slough's Candle (CC-BY 3.0)** because its flame is a separate mesh (hide it, reuse as our flame with an unshaded emissive orange material). CreativeTrio's CC0 Candlestick is the fallback (then the flame is a billboard QuadMesh with a teardrop shader).

### 2.1 Scene tree
```
Candle (Node3D, candle.gd)
 ├ WorldEnvironment (black bg, ambient 0.06 cool, glow on: the flame + arc bloom; Compatibility glow ok)
 ├ Camera3D (fov 32, ~0.9 m in front of the open switch box, slightly above, looking at the shelf)
 ├ RedFill (OmniLight3D, red 0.4) + KeyLamp (SpotLight3D warm 0.6, off once the candle burns)
 ├ Box (power_switch.tscn instance, Cover hidden, Interactable disabled) — continuity with the world prop
 ├ Shelf (MeshInstance3D BoxMesh under the lever) with TerminalPlus / TerminalMinus (brass cylinders, Label3D "+" "−"), 8 cm gap
 │   └ Wires (2 thin CylinderMesh red/black from terminals into the box)
 ├ CandleModel (candle.glb, in the gap; WickSocket Marker3D at the top)
 ├ Thread (Node3D at left, 12 cm tall) → Strand0..2 (CylinderMesh r 2 mm, rings 32, strand_twist shader, phase 0/120/240°)
 ├ Matchbox (BoxMesh, brown, striker strip) + Match (stick cylinder + head sphere; MatchFlame small emissive quad, hidden)
 ├ Flame (candle glb flame mesh, re-parented, scale 0) + FlameLight (OmniLight3D warm, range 1.5, energy 0)
 ├ Arc (Node3D, 2 × 4 thin emissive cyan CylinderMesh segments, hidden; rebuilt with jitter every 0.05 s)
 ├ TwistInput
 └ Hud (CanvasLayer) → Hint (twist_hint), Step (Label "1/3 Twist a wick"), Prompt (Label), Burst parent (Control)
```
### 2.2 Flow (`enum Phase {WICK, PLANT, STRIKE, LIGHT, CIRCUIT, DONE}`)
1. **WICK** (on load `Narrator.play(&"candle_intro")`): roll **clockwise** (`Hint.arrow_direction = 1`), `wick_degrees = 720` (12 steps); anticlockwise untwists (clamp ≥ 0). Each step: alternate `wick_twist_1/2` (AudioStreamRandomizer ±10 % pitch). Shader uniforms eased like the screwdriver: `twist = progress * 5 TAU`, `spread = mix(4 mm, 0.6 mm, progress)`; `Hint.progress = progress`.
   ```glsl
   // strand_twist.gdshader (spatial, vertex only + flat cotton colour)
   uniform float twist; uniform float phase; uniform float spread; uniform float height = 0.12;
   void vertex() { float t = VERTEX.y / height + 0.5; float a = phase + twist * t;
       VERTEX.xz += vec2(cos(a), sin(a)) * spread; }
   ```
   Done → `candle_wick_done`, Hint hides.
2. **PLANT** (auto, ~1 s): Thread tweens up, over and down into `WickSocket`, scale y 0.25 (it sticks out 3 cm); `slide_and_click` sfx. Step label "2/3 Strike a match", Prompt "Press X (or click) to strike".
3. **STRIKE**: X/click plays a scrape (match tweens along the striker). Rule of three: strikes 1–2 fizzle (short slice of `light_match`, a puff of grey quad), first fizzle → `candle_match_fizzle`; strike 3 → full `light_match.wav`, MatchFlame on.
4. **LIGHT** (auto): match tweens to the wick (0.6 s), `fire_lighting.wav` + `flame_whoosh_lookimadeathing.wav`, Flame scale 0 → 1 (back-ease), FlameLight energy 0 → 1.4, KeyLamp fades out; start `flame_crackle_loop` (looping AudioStreamPlayer, −16 dB). `flame_flicker.gd`: `scale.y = 1 + 0.07 sin(13t) + 0.05 noise(t)`, light energy follows. Match shakes out and drops.
5. **CIRCUIT** (auto, 1.2 s later): flame leans sideways and stretches (scale.x 1 → 2.2) toward both terminals, colour tween orange → cyan-white; Arc shows (zigzag segments terminal+ → flame tip → terminal−, re-jittered), `spark_zap_grinnell.wav`, `ComicBurst.spawn(hud, screen pos of flame, "ZZZAP!")`, lever on the box flips up by itself, then `power_on_neon_hum_kinoton.wav`; `Narrator.play(&"candle_circuit")`.
6. **DONE**: wait for the line (max 10 s, as in `screwdriver.gd`), `Story.switch_game_done(&"candle")` (sets power on → step FREE_ROAM, arrival cue `to_be_continued`), `Transition.change_scene(Story.next_switch_scene())` (= office, lights snap back via `Lighting`).
Esc at any phase: back to the office, the candle game restarts next time (keypad stays beaten).
Optional polish: a lit candle (same glb + flicker) on the world `PowerSwitch` when `Story.step > SWITCH_3`.

## 3. Narrator cues (`game/narration/<id>.tres`, NarratorCue, subtitle-only placeholders)
| id | once | placeholder line |
|---|---|---|
| `twist_me_bare_hands` | no | "It says TWIST ME. You are not wringing company art with your bare hands. You need a seeing tool." |
| `scope_pickup` | yes | "Binoculars! Now you can see the... no. That's a kaleidoscope. Somebody in Facilities has a very specific hobby." |
| `scope_open` | yes | "The painting wants a twist. The kaleidoscope twists. This is the most compatible relationship in the building." |
| `scope_almost` | yes | "Ooh, almost. It's on the tip of the painting's tongue." |
| `scope_solved` | no | "There it is. The password was in the art all along. As is corporate tradition." |
| `keypad_no_password` | yes | "You don't know the password. The painting does. Paintings know things." |
| `keypad_wrong_1` / `_2` | no | "Access denied. The coffee machine guessed better." / "Wrong again. The keypad is starting to take it personally." |
| `keypad_twist_me` | yes | "TWIST ME isn't a password. It's an instruction. Possibly a cry for help." |
| `keypad_old_password` | yes | "That's your computer password. You reuse passwords? In this economy?" |
| `keypad_right` | no | "Access granted. Behind the panel: one candle. No wick. Of course." |
| `candle_intro` | yes | "The fuse is a candle. Don't ask. Twist some thread into a wick." |
| `candle_wick_done` | no | "A hand-twisted wick. Artisanal. Facilities will bill you for it." |
| `candle_match_fizzle` | yes | "Pfft. Matches, like interns, need three tries." |
| `candle_circuit` | no | "And the flame completes the circuit. Fire is just electricity that went to art school. Do not look this up." |
Add them to the "TODO script" list in `docs/plan.md` when built.

## 4. Assets and credits
Copy unaltered (or the scratchpad-trimmed versions) into the project; add rows to `game/CREDITS.md`, `assets/audio/CREDITS.md`, per-model `CREDITS.md`. CC-BY 3.0 rows need author + link + licence + "modified: scaled/flame mesh reused".
| File (project) | Source | Credit line |
|---|---|---|
| `assets/models/binoculars/binoculars.glb` | `assets3d/binoculars/Binoculars_fd1MPYUTpLL.glb` | "Binoculars" by Ryan Sullivan, CC-BY 3.0, https://poly.pizza/m/fd1MPYUTpLL |
| `assets/models/candle/candle.glb` | `assets3d/candle/Candle_HFpLq6iqKu.glb` | "Candle" by Nick Slough, CC-BY 3.0, https://poly.pizza/m/HFpLq6iqKu (fallback: "Candlestick" by CreativeTrio, CC0, https://poly.pizza/m/tknOVwxT8B) |
| `sfx/400_sounds_pack/light_match.wav`, `fire_lighting.wav`, `slide_and_click.wav`, `brass_positive_long.wav` (drop the `pack_` prefix) | `audio2/out/pack_*.wav` | 400 Sounds Pack, Chequered Ink (existing row, update file count) |
| `sfx/freesound/flame_whoosh_lookimadeathing.wav` | Freesound 260554 "Basic Fire whoosh" | LookIMadeAThing, CC0 |
| `sfx/freesound/flame_crackle_loop_soundofsong.wav` (import loop Forward) | Freesound 650574 "fire crackling loop.wav" | soundofsong, CC0 |
| `sfx/freesound/wick_twist_1/2_noxsound.wav` | Freesound 559079 "Foley_Leather_Stress_Mono.wav" (cut) | Nox_Sound, CC0 |
| `sfx/freesound/power_on_neon_hum_kinoton.wav` | Freesound 351430 "Neon Lamp, Switch On, Hum" (cut) | Kinoton, CC0 |
| `sfx/freesound/spark_zap_grinnell.wav` | Freesound 512471 "Electric zap.wav" | michael_grinnell, CC0 |
| `sfx/freesound/quiz_wrong_buzzer_kevinvg207.wav` (keypad buzzer; may already come with the gargoyle quiz) | Freesound 331912 | per `audio2/meta.json` |

## 5. Web / Compatibility caveats
- SubViewport → ViewportTexture on a spatial ShaderMaterial and a canvas ColorRect: fine in Compatibility/WebGL2. Assign by code (`get_texture()`), `UPDATE_ONCE` (one 512² render, then free). Check sRGB: use `source_color` on the spatial sampler; compare wall vs scope colours in a screenshot.
- GLSL ES 3.00: const float arrays and int `%`/`&` are fine; keep `#include` to a `.gdshaderinc` (supported). No mipmaps on the viewport texture → no seam artefacts from per-wedge UV jumps.
- `hint_screen_texture` only in the optional gag (§1.8); test on the web build, cut if broken.
- Keypad text input: use `InputEventKey.unicode` (layout-correct in the browser); TwistInput uses `physical_keycode` (already proven). None of B H Y T F V X is bound to movement (WASD + X interact + Esc).
- Audio: crackle loop via import loop flag (Web "Sample" playback supports loops); every sfx through `Audio.play_sfx` like the screwdriver.
- Glow in the candle scene: Compatibility supports glow from 4.3+; if it looks wrong on web, rely on emissive + OmniLight only.

## 6. Test plan
Jump straight in: run the office with `GameState.story_step = Story.Step.SWITCH_3`, `power_on = false` (or F7 ×5 from the intro). Screenshots to `docs/map/screenshots/switch3/`:
1. `painting_wall.png`: west wall of the server room, painting with TWIST ME next to the switch (power out lighting); 2. `binoculars_desk.png` with the prompt; 3. `scope_far.png` (start, jumbled mandala); 4. `scope_almost.png` (1 step off: gold seams, "Almost!"); 5. `scope_solved.png` (clean word + PASSWORD label); 6. `keypad_wrong.png`, `keypad_right.png`; 7. `candle_wick_0/50/100.png`; 8. `candle_lit.png`; 9. `candle_arc.png`; 10. `office_lights_back.png`.
Logic checks (gdscript test or debug prints): `Kaleidoscope.ensure()` idempotent per step and cleared by `_go_to`; scope solve only after 0.6 s at error 0, overshoot flips the hint arrow; leaving the scope / office / keypad and returning keeps `has_scope`, `scope_solved`, password; keypad accepts case-insensitive input; `switch_game_done` order (kaleidoscope then candle) and FREE_ROAM + `to_be_continued` after the candle; Esc mid-candle returns and restarts the candle only. Web export smoke test (`export/web/index.html` via a local https/COOP server): painting texture visible, scope shader, keypad typing, candle sounds and loop.

## 7. Risks
- **Painting.fbx canvas UVs** may be an atlas sub-rect (Paintings2–4 textures are whole images, so probably 0–1). If not, add a `Canvas` QuadMesh 2 mm in front of the frame and put the shader there.
- **Wall space** next to the mirrored switch (racks, clock at y 2.9): verify by screenshot; fallback positions in §1.5.
- **Legibility**: 7 letters at 512² through 6 wedges; if "almost" is readable too early, raise `MULT` magnitudes or `STEP_DEG` to 20°; if the solve is too hard to notice, lower `smoothstep` width.
- **Twist feel**: 15° per key step with a 9–20 step target could feel long; tune `randi_range` (keep ≥ 6 so it can't be hit by accident).
- **Player freeze** touches `player.gd` input paths (Esc mouse release, saved pose); keep it a single flag and test returning from the keypad still restores the pose.
- **Model scale/orientation** of poly.pizza GLBs (often metres-off and Y-up/Z-up mixes): wrap in a scene with a fixed transform; verify CC-BY attribution lands in credits before export.
- Time: kaleidoscope ≈ 60 %, candle ≈ 40 %. If short on time, cut §1.8 and the world candle; strike can be a single X press.

## As built (kaleidoscope only; the candle is built separately)

- Files as planned under `game/minigames/switch/kaleidoscope/` (no `painting_source.tscn`: `PaintingSource` is a SubViewport built in code by `painting_source.gd`). Keypad registered in `SwitchGames`; the switch opens it, the right password calls `Story.switch_game_done(&"kaleidoscope")` and moves on to `Story.next_switch_scene()` (the candle; the placeholder screen until the candle merges).
- User decisions: painting only, the painting itself says TWIST ME (Label3D), no sticky note. Script lines used verbatim: `twist_me_bare_hands` (painting without binoculars), `scope_solved` (aligned), new `keypad_intro` (once, keypad first open). Other cues are the placeholders from §3.
- `Player.movement_locked` (the ESDF plan's name instead of `frozen`): skips look, movement, interact, Esc and the prompt. The scope view sets it and hides `hud.minimap` (restored on close). Verified: holding move_right + move_forward while rolling the ring doesn't move the player.
- Shader deviation: **12 wedges** (not 6) plus a radius swirl `sin(err) * 1.5 * r`. With 6 wedges and pure rotation the big letters stayed readable (just rotated) on the wall and at the scope's start. Ghosting/seams use `2|sin(err/2)|`, so they stay periodic and a full turn lines up again (`Kaleidoscope.error_steps` wraps mod 24 steps).
- Targets: `TARGETS = [6, 7, 8, 10, 16, 17, 18, 19, 20]` steps, picked by eye from a gallery of every start frame. Near half a turn all the wedges land upside down and the word reads fine. Past 12 the short way is anticlockwise: the hint's arrow starts the short way round and flips on an overshoot.
- Painting: Painting.fbx scaled (1.2, 2.4, 1) to a ~1 m square canvas; the shader remaps the canvas's UV sub-rect. C1-local (5.88, 1.65, −0.35), between the switch and the whiteboard after the mirror (in `MIRRORED_TO_WEST_WALL`). Binoculars on the ControlDesk at (−3.25, 0.949, 7.15), scaled 0.6. `StoryStage._check_off_path` pauses while a `scope_view` is open.
- Cut: §1.8 world-spin gag (deadline). Feedback label sits at the top so it clears the subtitles.

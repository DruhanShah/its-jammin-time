# Plan: switch restore games "wires" (SWITCH_1) and "valve" (SWITCH_2)

Status: plan only, nothing built yet. Both games are restore games: beating one calls
`Story.switch_game_done(id)`, which is the last game of its step, so it turns the power on (`GameState.set_power(true)`)
and the story moves on (SWITCH_1 → COMPUTER_2, SWITCH_2 → COMPUTER_3). `Story.next_switch_scene()` then returns the office.
Both follow the screwdriver's conventions (`minigames/switch/screwdriver/`): one scene per game under
`minigames/switch/<id>/`, `const ID`, Esc (`ui_cancel`) goes back to `Story.OFFICE` without fixing anything (progress in the
pair is kept, the game itself starts over), wait for the narrator's last line (max 10 s) before
`Transition.change_scene(Story.next_switch_scene())`, and a HUD panel styled like the screwdriver's (`Style_panel`: Title / Help / Count).

| | Wires | Valve |
|---|---|---|
| View | **2D** comic close-up (mouse drag needs exact hit-testing; Among Us is 2D, so the trap reads instantly) | **3D** close-up like the screwdriver (a turning wheel and glowing pipes read better in 3D; same camera/lighting kit) |
| Input | mouse drag-and-drop | TwistInput + TwistHint |
| Gag | the panel says MATCH THE COLOURS; matching is wrong, straight across is right; narrator mocks with escalating lines; the sign peels like the sticker | "lefty-loosey" is a lie: reverse thread; the hint arrow flips |
| Finish | pull the red lever (the one revealed under the cover) | the switchboard's lever flips itself up when the flow is full |

Shared sounds go once into `game/assets/audio/sfx/freesound/` (same folder as the screwdriver's), file names unchanged from
`scratchpad/audio2/out/`. Already prepared there as cuts (one-shots faded, loops crossfaded), so copy as is.

---

## 1. WIRES (`minigames/switch/wires/`, SWITCH_1 restore)

### Design
- Opens straight after the screwdriver (the cover fell off; the scene change is the "zoom in"). Continuity: the board is a
  flat comic drawing of the same box: grey metal `Color(0.42, 0.44, 0.46)`, yellow stripe on top `Color(0.95, 0.75, 0.1)` with
  black hazard diagonals, red lever `Color(0.85, 0.12, 0.08)` on its base, and the **same three wires** in the same order and
  colours as the screwdriver reveal: red `(0.9, 0.15, 0.1)`, blue `(0.15, 0.35, 0.95)`, yellow `(0.95, 0.8, 0.1)`.
- Layout (board 760×520, centred in the 1152×648 viewport): left terminal block with three loose wire stubs (rows y = 120 / 220 /
  320, red-blue-yellow top to bottom, as in Among Us), right terminal block with three sockets on the **same rows**, each with a
  coloured rim in a shuffled order: `socket_order = [1, 2, 0]` (blue, yellow, red). The lever sits bottom-centre (y ≈ 430),
  greyed out until all three wires are in. A riveted label plate between the rows: **"MATCH THE COLOURS"** (Comic Relief Bold).
- Rules, for wire `w` dropped on free socket `s` (rows are aligned, so "straight" is just `s == w`, never geometry):
  - `s == w` → **straight: correct.** Plug sound, "CLICK!" burst, wire stays. `socket_order` is a derangement
    (`socket_order[i] != i`, asserted in `_ready`), so a straight connection never matches colours.
  - `socket_order[s] == w` → **colour match: wrong.** Big zap + "ZZZT!" burst, board shakes, wire springs back, next mocking line.
  - otherwise → crossed (neither): small zap, springs back, `wires_crossed` (once).
  - dropped on nothing → springs back silently.
- Escalation: 3rd colour match peels the "MATCH THE COLOURS" plate (callback to the screw sticker) revealing the stencil underneath:
  **"STRAIGHT ACROSS. OBVIOUSLY."** That's the real hint for players who still don't get it.
- All 3 straight → lever lights up (pulsing yellow outline), Help = "Pull the lever!". Click (or drag up) the lever → lever
  flips up, breaker clunk, emergency tint fades to normal light with 3 quick flickers + neon hum, "KA-CHUNK!" burst,
  HUD Count "Wires: 3 / 3. Sparks: N." (N = zaps; echoes the screwdriver's "Stickers: 1 / 1"), `wires_done`, then exit.
- Emergency vs normal light (for screenshots too): a full-rect `EmergencyTint` ColorRect with `CanvasItemMaterial`
  `blend_mode = BLEND_MODE_MUL`, `color = Color(1.0, 0.5, 0.45)` slowly pulsing ±0.05, plus a halftone vignette; at the end
  it tweens to `Color.WHITE` (normal).

### Files
- `game/minigames/switch/wires/wires.tscn`, `wires.gd` (game logic), `wire_board.gd` (`class_name WireBoard`: drawing, drag, hit tests; no story code, so the driver can test it alone)
- `game/narration/wires_*.tres` (NarratorCue, subtitle-only placeholders)
- sounds into `game/assets/audio/sfx/freesound/`: `wire_plug_in_preyk.wav`, `spark_zap_grinnell.wav`, `spark_klein.wav`, `breaker_clunk_on_kyles.wav`, `power_on_neon_hum_kinoton.wav`
- edit `minigames/switch/switch_games.gd`, `assets/audio/CREDITS.md`, `game/CREDITS.md`, `docs/plan.md` (engineering log + script TODO), `docs/progress.md`

### Scene tree (`wires.tscn`)
```
Wires (Control, full rect, wires.gd)            mouse_filter PASS
├─ Backdrop (ColorRect, full rect)              ShaderMaterial core/ui/comic/halftone.gdshader: paper (0.10,0.10,0.12), dots (0.18,0.18,0.22), radial 1.0
├─ Board (Control, wire_board.gd)               anchors centre, 760×520, pivot_offset = size/2, mouse_filter STOP
├─ Burst (Control, full rect, mouse_filter IGNORE)   parent for ComicBurst.spawn()
├─ Sparks (CPUParticles2D)                      one_shot, explosiveness 1, 24 yellow-white streaks; moved to the socket per zap
├─ EmergencyTint (ColorRect, full rect, mouse_filter IGNORE, CanvasItemMaterial MUL)
├─ Hud (CanvasLayer)
│  └─ Panel (PanelContainer, Style_panel copied from screwdriver.tscn) / Box (VBox)
│     ├─ Title "Fix the wiring" (32)   ├─ Help "Drag each wire to a socket.\nEsc: leave" (18)   └─ Count "Wires: 0 / 3" (22)
└─ (sounds are exported AudioStreams on the root, played with Audio.play_sfx like the screwdriver)
```

### `wire_board.gd` (WireBoard)
```gdscript
class_name WireBoard extends Control
signal dropped(wire: int, socket: int)   # socket = -1: dropped on nothing
signal lever_pulled
const COLORS := [Color(0.9,0.15,0.1), Color(0.15,0.35,0.95), Color(0.95,0.8,0.1)]
const ROWS := [120.0, 220.0, 320.0]
const LEFT_X := 70.0; const STUB := 90.0; const RIGHT_X := 690.0
@export var socket_order := PackedInt32Array([1, 2, 0])   # colour index of each right socket (must be a derangement)
@export var grab_radius := 34.0
@export var snap_radius := 46.0
var connected := PackedInt32Array([-1, -1, -1])   # wire -> socket
var lever_ready := false: set = _set_lever_ready
var lever_up := 0.0          # 0 down .. 1 up (tweened)
var label_peel := 0.0        # 0 plate on .. 1 peeled off (tweened)
var _drag := -1; var _drag_pos := Vector2.ZERO
var _loose: Array[Vector2]   # current free-end position per wire (rest = tip(i)); tweened back on snap_back

func tip(i) -> Vector2: return Vector2(LEFT_X + STUB, ROWS[i])     # rest position of a loose plug
func anchor(i) -> Vector2: return Vector2(LEFT_X, ROWS[i])
func socket_pos(j) -> Vector2: return Vector2(RIGHT_X, ROWS[j])
func lever_rect() -> Rect2: return Rect2(size.x/2 - 40, 380, 80, 120)

func _gui_input(e):
    if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
        if e.pressed:
            var w := _free_wire_at(e.position)         # nearest unconnected wire whose _loose[w] is within grab_radius
            if w >= 0: _drag = w; _drag_pos = e.position; accept_event()
            elif lever_ready and lever_rect().has_point(e.position): lever_pulled.emit(); accept_event()
        elif _drag >= 0:
            var w := _drag; _drag = -1
            _loose[w] = e.position
            dropped.emit(w, _socket_at(e.position))     # nearest free socket within snap_radius, else -1
            accept_event()
    elif e is InputEventMouseMotion and _drag >= 0:
        _drag_pos = e.position; _loose[_drag] = e.position; queue_redraw()
    # mouse_default_cursor_shape: set CURSOR_POINTING_HAND in _process when hovering a free plug or a ready lever (glove tap)

func plug(w, s): connected[w] = s; _loose[w] = socket_pos(s); queue_redraw()
func snap_back(w): create_tween().tween_method(func(p): _loose[w] = p; queue_redraw(), _loose[w], tip(w), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
func all_straight() -> bool: return connected == PackedInt32Array([0, 1, 2])

func _draw():
    # 1 shadow rect (+8,+8, black 0.6), 2 box (grey) with 6 px black outline, 3 yellow stripe + black diagonals,
    # 4 terminal blocks (dark grey, 3 brass screws each), 5 sockets: black hole + 8 px coloured rim (socket_order),
    # 6 label plate (peel: scale.y = 1 - label_peel, skew, under it the "STRAIGHT ACROSS. OBVIOUSLY." text),
    # 7 lever (base + red handle, rotated by lerp(+30°, -30°, lever_up); yellow pulsing outline if lever_ready),
    # 8 wires last (on top): for each w, _draw_wire(anchor(w), _loose[w], COLORS[w])
func _draw_wire(a, b, color):
    # quadratic bezier, control = (a+b)/2 + Vector2(0, 24 + 0.12 * a.distance_to(b)) (sag); 24 samples
    # draw_polyline(pts, Color.BLACK, 20, true); draw_polyline(pts, color, 13, true); highlight: color.lightened(0.4), 4 px, offset (0,-3)
    # plug at b: rounded rect 34×20 rotated along the last tangent, black outline, copper tip 8×10
```
Font: `get_theme_default_font()` (project theme = Comic Relief) at 30 px for the label.

### `wires.gd` (game logic)
```gdscript
extends Control
const ID := &"wires"
const MATCH_CUES: Array[StringName] = [&"wires_match_1", &"wires_match_2", &"wires_match_3", &"wires_match_4", &"wires_match_5"]
@export var plug_sound: AudioStream    # wire_plug_in_preyk, 0 dB
@export var zap_sound: AudioStream     # spark_zap_grinnell, -2 dB
@export var small_zap_sound: AudioStream # spark_klein, -6 dB
@export var lever_sound: AudioStream   # breaker_clunk_on_kyles, -2 dB
@export var hum_sound: AudioStream     # power_on_neon_hum_kinoton, -8 dB
@export var exit_delay := 1.5
@export var max_line_wait := 10.0
var _matches := 0      # colour-match attempts
var _mocked := 0       # mocking lines actually played
var _sparks := 0
var _done := false

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    ComicCursor.apply()
    _board.dropped.connect(_on_dropped); _board.lever_pulled.connect(_on_lever)
    _board.scale = Vector2(0.85, 0.85); create_tween().tween_property(_board, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)
    Narrator.play(&"wires_intro")     # once
func _exit_tree(): ComicCursor.reset()
func _unhandled_input(e): if e.is_action_pressed("ui_cancel") and not _done: Transition.change_scene(Story.OFFICE)

func _on_dropped(w, s):
    if _done: return
    if s < 0: _board.snap_back(w); return
    if s == w:
        _board.plug(w, s); Audio.play_sfx(plug_sound); ComicBurst.spawn($Burst, _global(s), "CLICK!", Color("#7dff7d"))
        Narrator.play(&"wires_finally" if _matches > 0 else &"wires_straight_first")   # both once
        _update_count()
        if _board.all_straight(): _board.lever_ready = true; $Hud/.../Help.text = "Pull the lever!\nEsc: leave"
    elif _board.socket_order[s] == w:
        _matches += 1; _zap(s, zap_sound, "ZZZT!"); _board.snap_back(w); _shake()
        if not Narrator.is_speaking():                   # escalate only through lines the player actually saw
            Narrator.play(MATCH_CUES[min(_mocked, MATCH_CUES.size() - 1)]); _mocked += 1
        if _matches == 3: create_tween().tween_property(_board, "label_peel", 1.0, 0.8)   # + a paper rustle is optional
    else:
        _zap(s, small_zap_sound, "fzt"); _board.snap_back(w); Narrator.play(&"wires_crossed")   # once

func _on_lever():
    _done = true; _board.lever_ready = false
    create_tween().tween_property(_board, "lever_up", 1.0, 0.18).set_trans(Tween.TRANS_BACK)
    Audio.play_sfx(lever_sound, -2.0)
    ComicBurst.spawn($Burst, _board.get_global_transform_with_canvas() * _board.lever_rect().get_center(), "KA-CHUNK!")
    $Hud/.../Count.text = "Wires: 3 / 3. Sparks: %d." % _sparks
    var t := create_tween()     # flicker on: MUL tint red -> white -> red -> white -> white (0.08 s steps), then hum
    ...; t.tween_callback(Audio.play_sfx.bind(hum_sound, -8.0))
    Narrator.play(&"wires_done")
    await t.finished; await get_tree().create_timer(exit_delay).timeout
    var waited := 0.0
    while Narrator.is_speaking() and waited < max_line_wait: await get_tree().create_timer(0.2).timeout; waited += 0.2
    Story.switch_game_done(ID)          # last game of SWITCH_1 -> power on -> COMPUTER_2
    Transition.change_scene(Story.next_switch_scene())   # = office
```
`_zap(s, stream, word)`: `_sparks += 1`, move `Sparks` to `_global(s)` and `restart()`, `Audio.play_sfx`, `ComicBurst.spawn(..., word, Color("#ff5a3c"))`.
`_shake()`: tween `_board.position` ±10 px ×4 over 0.25 s.

### Narrator cues (subtitle-only placeholders, `game/narration/`)
| id | once | placeholder line |
|---|---|---|
| `wires_intro` | yes | "Three wires, three sockets. Even you can't get this wrong. Just do what the sign says." |
| `wires_match_1` | no | "Red to red. Bold. Electricity is colourblind, by the way." |
| `wires_match_2` | no | "Matching colours again. It's a fuse box, not a sock drawer." |
| `wires_match_3` | no | "The sign says match the colours. The sign was printed by Facilities. Facilities also printed the screws." |
| `wires_match_4` | no | "Straight. Across. Like a ruler. You've seen a ruler." |
| `wires_match_5` | no | "I'm going to start billing you per spark." (repeats from here) |
| `wires_crossed` | yes | "Crossing the wires. That's how the last intern got his haircut." |
| `wires_straight_first` | yes | "Straight across, first try. Who told you? Was it the sign? It's lying." |
| `wires_finally` | yes | "Oh, NOW it's straight. Took you a few sparks." |
| `wires_done` | yes | "Power's back. All it took was ignoring every instruction you were given. You'll go far here." |
Add them to the script TODO list in `docs/plan.md`.

### Registration
`switch_games.gd`: `&"wires": {verb = "fix the wiring", scene = "res://minigames/switch/wires/wires.tscn"},`. The screwdriver already
chains into `Story.next_switch_scene()`, so nothing else changes.

### Optional continuity polish (small, separate commit)
- `screwdriver.tscn`: make the three revealed wires visibly *unplugged* (ends with little plug boxes, three empty sockets on the
  right) so the next scene is clearly the zoomed-in version.
- `power_switch.tscn/.gd`: an `Interior` node (three short wire meshes) shown when the cover is off; dangling while
  `Story.switch_game() == &"wires"`, straight once beaten.

---

## 2. VALVE (`minigames/switch/valve/`, SWITCH_2 restore)

### Design
- 3D close-up with the screwdriver's look: dark background, telephoto 30° camera, warm lamp + red emergency fill. Left: the
  "mains" pipe coming out of the wall (flange + the hazard diamond `props/hazard_sign.tscn`). Middle: a brass valve body with a
  **red hand wheel** on its stem, facing the camera, and a pressure gauge above it. Right: the same switchboard box as the world
  prop (grey box, yellow stripe, red lever down, a small indicator bulb). Copper pipe connects all three. Two **glass sight
  sections** show the electricity as glowing blue-white liquid: upstream (mains → valve) always full and churning ("it's stuck
  at the valve"), downstream (valve → switchboard) filling and flowing with the valve's opening. Leaky joints spit sparks
  in proportion to the flow. Behind/left, Phiam Ash's steampunk pipes as plumber set dressing (static).
- Gag (one): **lefty-loosey is a lie.** The HUD and the TwistHint (arrow −1) say "Lefty-loosey: roll the keys anticlockwise".
  Anticlockwise only tightens: the wheel turns stiffly (½ speed, judder), squeaks, and the trickle of electricity dies.
  After `reverse_degrees` 240° → pipe clunk, small camera shake, `valve_reverse_thread`, the hint arrow flips to +1 and comes
  back full size, Help = "Reverse thread! Righty-loosey: roll the keys clockwise". If the player goes clockwise first, the
  gag lands the other way after `early_degrees` 120° (`valve_righty_early`). Either way it fires once.
- After the gag, clockwise opens (`open_turns` 3 = 18 key steps), anticlockwise closes again (`valve_closing`, once). Flow
  eases toward the opening. At 50 % `valve_leak` (once). Full open and flow ≥ 0.97 → finish: surge sound, bulb flares, the
  switchboard lever flips up by itself + breaker clunk, emergency lights out / normal lights in with a flicker + neon hum,
  "FWOOSH!" burst on the HUD, `valve_done`, wait for the line, `switch_game_done(&"valve")` → power on → COMPUTER_3 → office.
- Stretch (only if time): the wheel comes off in the last half turn and spins away; skip for the jam (one gag is enough).

### Files
- `game/minigames/switch/valve/valve.tscn`, `valve.gd`, `pipe_flow.gdshader`
- `game/assets/models/pipes/steampunk_pipes.glb` (renamed from `Steampunk_pipes_aBug7Q_ZiS_.glb`, unchanged) + `CREDITS.md`
- optional `game/assets/models/pipes/quaternius_pipes.glb` (from `Pipes_GB6AFkoiZb.glb`) for a pair of grey elbows dropping from the valve into the floor; skip if the steampunk piece is enough
- sounds into `game/assets/audio/sfx/freesound/`: `valve_squeak_1/2/3_joedeshon.wav`, `valve_turn_rusty_loop_noxsound.wav`, `pipe_clunk_brittmosel.wav`, `pipe_flow_loop_rutgermuller.wav`, `electric_surge_fkurz.wav`, `spark_klein.wav`, `breaker_clunk_on_kyles.wav`, `power_on_neon_hum_kinoton.wav` (last three shared with wires). Set `edit/loop_mode=2` (Forward) in the `.import` of the two `_loop` files (as `chair_roll_loop.wav.import` does).
- `game/narration/valve_*.tres`
- small addition to `core/input/twist_hint.gd`: public `restart()` (sets `_good = 0`, `_idle = 0`, `_set_compact(false)`) so the flipped arrow is shown big again
- edit `switch_games.gd`, credits files, `docs/plan.md`, `docs/progress.md`

### Scene tree (`valve.tscn`)
```
Valve (Node3D, valve.gd)
├─ WorldEnvironment            bg (0.04,0.04,0.05), ambient 0.35 (same as screwdriver) + glow on (intensity 0.8, bloom 0.1) for the plasma
├─ Camera3D                    fov 30, from front-right-above like the screwdriver, framing x −1.0..1.0 (tune with screenshots)
├─ Emergency (Node3D)          Lamp (OmniLight warm, energy 1.6) + EmergencyLight (red, 0.8): copy the screwdriver's
├─ Normal (Node3D, visible=false) Ceiling (OmniLight3D cool white (0.9,0.95,1), energy 0 -> 1.3, range 4, at (0, 1.5, 1))
├─ Wall (QuadMesh 4×3, Mat_wall)
├─ Backdrop (steampunk_pipes.glb, scale ≈0.22 → ~1.1 m tall, at (−1.25, −0.55, −0.3), rotated to read; decor only)
├─ Mains (Node3D, x −0.85): Flange (CylinderMesh), Stub pipe, HazardSign (hazard_sign.tscn)
├─ PipeIn  (Node3D): Copper (CylinderMesh r 0.035, rotated 90° z) + Glass (CylinderMesh r 0.045, transparent) + Plasma (CylinderMesh r 0.03, ShaderMaterial pipe_flow, fill 1, flow 0.6)
├─ Valve (Node3D, x −0.05)
│  ├─ Body (CylinderMesh brass (0.74,0.33,0.06) metallic 0.7)   ├─ Bonnet   ├─ Stem (CylinderMesh along +z)
│  ├─ Wheel (Node3D, pivot at the stem tip; rotation.z driven)
│  │  └─ Rim (TorusMesh inner 0.075 outer 0.095, rotated x 90°), Spoke1..4 (BoxMesh), Hub (CylinderMesh); red (0.91,0.05,0.03) to match the steampunk wheels
│  └─ Gauge (Node3D above): Dial (flat CylinderMesh, white), Needle (Node3D pivot + BoxMesh black), Rim
├─ PipeOut (Node3D): Copper + Glass + Plasma (ShaderMaterial pipe_flow, `fill`/`flow` driven) up to the switchboard
├─ Joints: Joint1, Joint2 (SphereMesh copper) each with LeakSparks (CPUParticles3D: 30, lifetime 0.4, spread 40°, gravity −4, scale curve, emission colour (0.7,0.9,1))
├─ Switchboard (Node3D, x +0.75): Box, Stripe, LeverBase, Lever (copy meshes/materials from power_switch.tscn), Bulb (SphereMesh r 0.035, emission ∝ flow)
├─ TwistInput (twist_input.gd)
├─ TurnLoop (AudioStreamPlayer, valve_turn_rusty_loop, bus SFX, volume −80, playing)
├─ FlowLoop (AudioStreamPlayer, pipe_flow_loop, bus SFX, volume −80, playing)
├─ Surge (AudioStreamPlayer, electric_surge_fkurz, bus SFX)    stopped with a 0.6 s fade at 2.5 s (the clip is 6.9 s)
└─ Hud (CanvasLayer)
   ├─ Panel/Box: Title "Open the valve" / Help "Lefty-loosey: roll the keys around G anticlockwise.\nEsc: leave" / Count "Flow: 0 %"
   ├─ Burst (Control, full rect, mouse_filter IGNORE)
   └─ Hint (twist_hint.tscn, twist = ../../TwistInput, arrow_direction = -1, anchored like the screwdriver's)
```

### `pipe_flow.gdshader` (Compatibility-safe: no screen reads, `discard` is fine)
```glsl
shader_type spatial;
render_mode unshaded, cull_back;
uniform float fill : hint_range(0.0, 1.0) = 1.0;   // how far along the pipe the electricity has got (from the valve end)
uniform float flow : hint_range(0.0, 1.0) = 0.0;   // speed + brightness
uniform float half_length = 0.2;                   // CylinderMesh height / 2 (mesh is along local Y)
uniform float from_top = 0.0;                      // 1: fills from +Y end (pick per pipe so it starts at the valve)
uniform vec4 color : source_color = vec4(0.55, 0.85, 1.0, 1.0);
varying float along;
void vertex() { float a = VERTEX.y / (2.0 * half_length) + 0.5; along = mix(a, 1.0 - a, from_top); }
void fragment() {
    if (along > fill) discard;
    float bands = 0.5 + 0.5 * sin((along * 14.0 - TIME * (1.5 + 9.0 * flow)) * 6.2832);
    float boil = 0.5 + 0.5 * sin(UV.x * 40.0 + TIME * 7.0 + along * 30.0);
    ALBEDO = color.rgb * (0.35 + 0.9 * flow) * (0.75 + 0.35 * bands + 0.15 * boil);
}
```
(With glow on, ALBEDO > 1 blooms in Compatibility via the environment's glow; if it doesn't, use `EMISSION` in an unshaded-off material. Check in the first screenshot.)

### `valve.gd`
```gdscript
extends Node3D
const ID := &"valve"
@export var open_turns := 3.0          # clockwise turns to open fully (18 key steps)
@export var reverse_degrees := 240.0   # anticlockwise before the reverse-thread gag
@export var early_degrees := 120.0     # clockwise before the gag, if they never tried "lefty"
@export var trickle := 0.08            # flow before anything is touched (shows it's stuck)
@export var flow_rate := 1.6           # how fast the flow follows the opening (1/s)
@export var wheel_follow := 12.0
@export var squeak_every := 180.0
@export var exit_delay := 1.5
@export var max_line_wait := 10.0
@export var squeak_sound: AudioStream  # AudioStreamRandomizer of valve_squeak_1/2/3, random_pitch 1.1
@export var clunk_sound: AudioStream; @export var spark_sound: AudioStream
@export var lever_sound: AudioStream;  @export var hum_sound: AudioStream
var flow := 0.0
var _opened := 0.0       # degrees opened, 0..open_turns*360
var _tightened := 0.0    # anticlockwise degrees before the gag
var _gag := false
var _wheel_deg := 0.0    # target wheel angle (signed, clockwise +); _shown_deg eases toward it
var _shown_deg := 0.0
var _since_squeak := 0.0
var _turning := 0.0      # seconds left of "the wheel is moving" (drives TurnLoop)
var _done := false

func _ready():
    Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
    _twist.twisted.connect(_on_twisted)
    flow = trickle
    Narrator.play(&"valve_intro")   # once; note: the TwistHint's first-ever twist_tutorial already played in SWITCH_1

func _on_twisted(d: float):          # d: +60 clockwise, -60 anticlockwise (120 on skips)
    if _done: return
    _turning = 0.3
    if not _gag:
        if d < 0.0:
            _tightened -= d; _wheel_deg += d * 0.5          # stiff
            if _tightened >= reverse_degrees: _reverse_gag(&"valve_reverse_thread")
        else:
            _opened += d; _wheel_deg += d
            if _opened >= early_degrees: _reverse_gag(&"valve_righty_early")
    else:
        var before := _opened
        _opened = clampf(_opened + d, 0.0, _need())
        _wheel_deg += _opened - before
        if d < 0.0 and _opened < before: Narrator.play(&"valve_closing")   # once
        if _opened == before: return                                       # against a stop: no sound
    _since_squeak += absf(d)
    if _since_squeak >= squeak_every: _since_squeak = 0.0; Audio.play_sfx(squeak_sound, -4.0)

func _reverse_gag(cue: StringName):
    _gag = true
    Audio.play_sfx(clunk_sound, -2.0); _shake_camera(0.02, 0.3)
    Narrator.play(cue)
    _hint.arrow_direction = 1; _hint.restart()
    _help.text = "Reverse thread! Righty-loosey: roll the keys around G clockwise.\nEsc: leave"

func _process(dt):
    if _done: return
    var opening := _opened / _need()
    var target := opening if _gag else maxf(trickle * (1.0 - clampf(_tightened / reverse_degrees, 0.0, 1.0)), opening)
    flow = move_toward(flow, target, flow_rate * dt)
    _shown_deg = lerpf(_shown_deg, _wheel_deg, 1.0 - exp(-wheel_follow * dt))
    _wheel.rotation.z = -deg_to_rad(_shown_deg)                      # wheel faces +z: clockwise on screen = negative z
    if not _gag and _turning > 0.0 and _tightened > 0.0: _wheel.position.x = randf_range(-0.002, 0.002)   # judder
    _plasma_out.set_instance_shader_parameter... or material.set_shader_parameter("fill", flow); ("flow", flow)
    _needle.rotation.z = deg_to_rad(lerpf(120.0, -120.0, flow))
    _bulb_mat.emission_energy_multiplier = flow * 4.0
    for s in _leaks: s.emitting = flow > 0.15; s.amount_ratio = flow
    _turning -= dt
    _turn_loop.volume_db = move_toward(_turn_loop.volume_db, -6.0 if _turning > 0.0 else -80.0, 300.0 * dt)
    _flow_loop.volume_db = linear_to_db(maxf(flow, 0.001)) - 4.0
    _hint.progress = opening if _gag else 0.0
    _count.text = "Flow: %d %%" % roundi(flow * 100.0)
    if opening >= 0.5: Narrator.play(&"valve_leak")                 # once (cue flag stops repeats)
    if _gag and opening >= 1.0 and flow >= 0.97: _finish()

func _finish():
    _done = true; _hint.hide(); _turn_loop.stop()
    _surge.play(); create_tween().tween_property(_surge, "volume_db", -40.0, 0.6).set_delay(2.5)
    var t := create_tween()
    t.tween_property(_bulb_mat, "emission_energy_multiplier", 12.0, 0.4)
    t.tween_property(_lever, "rotation:x", deg_to_rad(-30.0), 0.18).set_trans(Tween.TRANS_BACK)
    t.tween_callback(Audio.play_sfx.bind(lever_sound, -2.0))
    t.tween_callback(_lights_on)        # Emergency hide, Normal show, energy 0→1.3 with 3 flicker steps, hum at -8 dB
    t.tween_callback(func(): ComicBurst.spawn(_burst, _camera.unproject_position(_valve.global_position), "FWOOSH!"))
    Narrator.play(&"valve_done")
    await t.finished; await get_tree().create_timer(exit_delay).timeout
    (wait for the line, max_line_wait, like the screwdriver)
    Story.switch_game_done(ID)          # last game of SWITCH_2 -> power on -> COMPUTER_3
    Transition.change_scene(Story.next_switch_scene())

func _unhandled_input(e): if e.is_action_pressed("ui_cancel") and not _done: Transition.change_scene(Story.OFFICE)
func _need() -> float: return open_turns * 360.0
```
Occasional `Audio.play_sfx(spark_sound, -10)` from a random leak when flow > 0.3 (timer 0.4–1.2 s).

### Narrator cues (subtitle-only placeholders)
| id | once | placeholder line |
|---|---|---|
| `valve_intro` | yes | "The new switchboard runs on plumbing. Don't look at me. Facilities hired a plumber instead of an electrician. He was cheaper." |
| `valve_reverse_thread` | yes | "Lefty-loosey? Not this one. Reverse thread. The plumber was left-handed. And spiteful." |
| `valve_righty_early` | yes | "Righty-tighty... loosens it? Reverse thread. You knew that. Of course you did." |
| `valve_closing` | yes | "Other way. You're un-fixing it. Bold strategy." |
| `valve_leak` | yes | "It's not leaking. It's sharing." |
| `valve_done` | yes | "Electricity, flowing like water. The safety manual has a whole chapter on why you never do that." |

### Registration
`switch_games.gd`: `&"valve": {verb = "turn the valve", scene = "res://minigames/switch/valve/valve.tscn"},`. The gargoyles
obstacle before it is not built yet; until then the placeholder screen beats it and chains into the valve scene.

### Optional continuity polish
`power_switch.tscn/.gd`: a `Plumbing` node (copper pipe from the wall into the box side, a small red wheel) shown when
`Story.step >= Story.Step.SWITCH_2` ("this switchboard doesn't work like the last one"); set in `_sync()`.

---

## 3. Assets and credits (both games)

Sounds (all Freesound, CC0 1.0, cuts from the HQ preview made by `scratchpad/audio2/jobs.py`; record the cut in the CREDITS table like the existing rows):

| File | Source sound | Author | URL | Cut (jobs.py) | Used for |
|---|---|---|---|---|---|
| `wire_plug_in_preyk.wav` | "plug getting connected to wall socket" | preyk | https://freesound.org/people/preyk/sounds/525017/ | 0–0.38 s | wire plugged straight |
| `spark_zap_grinnell.wav` | "Electric zap.wav" | michael_grinnell | https://freesound.org/people/michael_grinnell/sounds/512471/ | 0–0.22 s | colour-matched wire zaps |
| `spark_klein.wav` | "Spark" | elliott.klein | https://freesound.org/people/elliott.klein/sounds/189630/ | 0–0.17 s | crossed wire; valve leak sparks |
| `breaker_clunk_on_kyles.wav` | "switch big breaker metal click on, off.flac" | kyles | https://freesound.org/people/kyles/sounds/451933/ | 0.10–1.40 s, mono | lever up (both games) |
| `power_on_neon_hum_kinoton.wav` | "Neon Lamp, Switch On, Hum" | Kinoton | https://freesound.org/people/Kinoton/sounds/351430/ | 0.2–6.0 s | lights back (both games) |
| `valve_squeak_1/2/3_joedeshon.wav` | "squeak_01.wav" | joedeshon | https://freesound.org/people/joedeshon/sounds/339184/ | 0.30–1.20, 2.10–3.00, 3.85–4.90 s | wheel squeaks (randomizer) |
| `valve_turn_rusty_loop_noxsound.wav` | "Foley_Mechanism_Wheel_Moderate_Rusty_Loop_Mono.wav" | Nox_Sound | https://freesound.org/people/Nox_Sound/sounds/559470/ | 8.0 s loop from 0.3 s | while the wheel turns (loop) |
| `pipe_clunk_brittmosel.wav` | "Hitting a Pipe with a Hammer" | brittmosel | https://freesound.org/people/brittmosel/sounds/530216/ | 16.64–17.80 s | reverse-thread gag |
| `pipe_flow_loop_rutgermuller.wav` | "Pressure Meter Pipe Noises 1.aif" | RutgerMuller | https://freesound.org/people/RutgerMuller/sounds/104087/ | 8.0 s loop from 12.0 s | electricity flowing (loop) |
| `electric_surge_fkurz.wav` | "high-voltage.wav" | fkurz | https://freesound.org/people/fkurz/sounds/136614/ | 0–6.9 s (faded out at 2.5 s in game) | valve finish |

Credit line (optional under CC0), add to `game/CREDITS.md` and `assets/audio/CREDITS.md`:
> Wire and spark sounds by preyk, michael_grinnell, elliott.klein; breaker by kyles; neon hum by Kinoton; valve squeaks by joedeshon, rusty wheel by Nox_Sound, pipe clunk by brittmosel, pipe noises by RutgerMuller, high voltage by fkurz (Freesound), CC0

Models (`assets/models/pipes/CREDITS.md`, row in `game/CREDITS.md`):
- **"Steampunk pipes"** by Phiam Ash, https://poly.pizza/m/aBug7Q_ZiS_, **CC-BY 3.0** (https://creativecommons.org/licenses/by/3.0/): attribution **required**, must be in the shipped credits. File `steampunk_pipes.glb` (renamed, unchanged). 28 separate mesh nodes with baked vertex positions (no per-node transforms), ~4.9 m tall raw, so it's scaled ≈0.22. Its wheels are part of the decor and are not animated (their pivots would need re-centring).
  > Steampunk pipes model by Phiam Ash (Poly Pizza), CC-BY 3.0
- optional **"Pipes"** by Quaternius, https://poly.pizza/m/GB6AFkoiZb, CC0 1.0. Raw mesh bounds are ~1 cm (the FBX root probably carries the scale): check the imported size before placing.
  > Pipes model by Quaternius (Poly Pizza), CC0

Everything else (wheel, valve body, gauge, pipes, switchboard, the 2D board) is primitives / `_draw()` made in the project.

---

## 4. Test plan

Drivers live in the scratchpad (not the repo), are `extends SceneTree`, and run **windowed** (screenshots need rendering):
`/Applications/Godot.app/Contents/MacOS/Godot --path game -s <driver.gd>`; window 1152×648 (`DisplayServer.window_set_size`), so
viewport = window coordinates with the `canvas_items` stretch. Each driver: sets `GameState.story_step`, `switch_progress = 1`
(obstacle beaten) and `GameState.set_power(false)`, then `change_scene_to_file(<scene>)`, waits 1 s, runs checks, prints
`PASS/FAIL`, saves `root.get_texture().get_image().save_png(...)`, quits with `fails`; a 120 s timeout quits(2). Shots go to
`scratchpad/switch_restore/shots/`; look at every one and judge it (house rule: screenshot every added asset).

### Wires driver (`wires_driver.gd`)
Helpers: `to_screen(p) = board.get_global_transform_with_canvas() * p`; `drag(a, b)`: push `InputEventMouseButton` (left,
pressed, position a) via `Input.parse_input_event`, 8 `InputEventMouseMotion` steps toward b (await `process_frame` each), release
at b, await 2 frames. Hooks to observe: `board.connected`, `Narrator.current_cue`, the game's `_sparks`, `board.label_peel`.
1. Drop wire 0 on empty board space → `connected == [-1,-1,-1]`, no cue, plug back at `tip(0)` after 0.4 s.
2. Wire 0 (red) → socket 2 (red rim) → `connected[0] == -1`, `_sparks == 1`, cue `wires_match_1`. Shot `02_zap.png` mid-burst.
3. Wait until `not Narrator.is_speaking()`, repeat twice → cues `wires_match_2`, `wires_match_3`; after the 3rd, `label_peel → 1`. Shot `03_label_peeled.png`.
4. Repeat quickly without waiting → `_mocked` doesn't skip lines (no cue played while one is speaking).
5. Wire 0 → socket 1 (crossed) → `wires_crossed`, snaps back.
6. Mid-drag shot `01_dragging.png` (emergency tint, wire sagging under the cursor; glove cursor isn't in screenshots, fine).
7. Wires 0→0, 1→1, 2→2 → `connected == [0,1,2]`, `lever_ready`, cue `wires_finally`. Shot `04_all_in.png`.
8. Click the lever centre → within 15 s the scene is the office, `GameState.power_on`, `story_step == Step.COMPUTER_2`, `switch_progress == 0`. Shot `05_power_on.png` taken 0.6 s after the click (normal light).
9. Fresh run: Esc mid-game → office, `switch_progress == 1`, power still off.
10. Chain: start at the screwdriver (`switch_progress = 0`), run the screwdriver by feeding anticlockwise ring keys (`InputEventKey` with `physical_keycode`, 0.08 s apart: `BHYTFV` repeated) → lands in `wires.tscn` (`current_scene.name == "Wires"`), mouse visible.
Also manual: play from F7 into SWITCH_1, do it by hand once with a real mouse, check the cursor shape over plugs and the lever.

### Valve driver (`valve_driver.gd`)
Helpers: `roll(seq, dt = 0.08)` pushes press+release `InputEventKey`s with `physical_keycode` for each letter via
`Input.parse_input_event` and waits `dt` (clockwise = `TYHBVF`, anticlockwise = `BHYTFV`; keep `dt` < 0.7 s timeout).
1. Load, wait 1 s: `flow ≈ trickle`, `Flow: 8 %`. Shot `01_closed.png` (emergency light, upstream glowing, downstream dry).
2. Anticlockwise 4 steps (240°) → `_gag`, cue `valve_reverse_thread`, `hint.arrow_direction == 1`, `_opened == 0`, flow → 0 within 1 s. Shot `02_gag.png`.
3. Clockwise 9 steps → `_opened == 540`, flow → ~0.5, leaks emitting, cue `valve_leak`. Shot `03_half.png`.
4. Anticlockwise 2 steps → `_opened == 420`, cue `valve_closing`.
5. Clockwise until open (11 more steps) → finish within 4 s; shot `04_open.png` (lever up, normal light) 0.8 s after; within 15 s: office, `power_on`, `story_step == Step.COMPUTER_3`.
6. Fresh run, clockwise 2 steps first → cue `valve_righty_early`, gag done, opening counts from 120°.
7. Fresh run: Esc → office, `switch_progress == 1`, power off.
8. Headless sanity (`--headless`, no shots): load both scenes, no script errors in the log (also run the editor's error check; see the Maintenance item in progress.md).

### Screenshots: normal + emergency light
Each close-up has both states in-scene (wires: `EmergencyTint` red vs white; valve: `Emergency` vs `Normal` light groups). The
driver shoots the emergency state during play and the normal state after the finish, plus one extra per game with the end state
forced early (`_lights_on()` / tint white) so the full board is judged in both lights side by side. In-world: if the optional
prop polish is built, F7 to SWITCH_1/SWITCH_2 and shoot the switch prop with the lights out (and F5 power on) via the
`shots_p2.gd`-style camera driver.

---

## 5. Risks and mitigations
- **Mouse in the wires game:** coming from the screwdriver the mouse is `HIDDEN`; the wires scene must set `VISIBLE` and apply
  `ComicCursor`, and `reset()` in `_exit_tree()` (the office re-captures the mouse; verify by returning with Esc).
- **The trap must be legible, not frustrating:** derangement order guarantees colour-match ≠ straight; the label peel after 3
  matches spells the answer; nothing is lost on a wrong drop. If playtesters stall, peel after 2.
- **Narrator interruptions:** rapid wrong drops would cut lines; escalation only advances when a line was actually played while
  not speaking. `wires_done` / `valve_done` are waited for (max 10 s) before the scene change, since `Narrator` stops lines on
  scene change.
- **Reverse-thread gag reads as a bug:** keep the hint's arrow flip + Help text + the line together in the same frame, and make
  the wheel judder/squeak (feels "stuck", not broken). `TwistHint.restart()` is a new public method on a shared widget: keep it
  tiny; the screwdriver doesn't call it.
- **Compatibility renderer:** glow/bloom on unshaded ALBEDO > 1 may look flat; fallback to emission. `CPUParticles3D` only (no GPU
  particles in web). Transparent glass + unshaded plasma sorting: plasma is inside glass, set glass `render_priority` −1 or drop
  the glass if sorting flickers.
- **Steampunk model:** 28 nodes with baked vertices, CC-BY. It may look busy or clash with the primitives; judge from the first
  screenshot and drop it (the game works without it). If dropped, remove its credits.
- **Loop sounds:** `valve_turn_rusty_loop` and `pipe_flow_loop` must be imported with Loop Mode Forward or they stop after 8 s.
  The 6.9 s surge is long: it's faded out at 2.5 s.
- **Story side effects:** `switch_game_done()` on the last game sets the power on, which immediately runs `Story._go_to(next step)`
  (queues the next computer visit); `next_switch_scene()` is then the office. Don't call `GameState.set_power(true)` directly.
  The gargoyles game is still a placeholder, so test the valve with `switch_progress = 1`.
- **Twist hint tutorial:** `twist_tutorial` is `once`, already used by the screwdriver; `valve_intro` must not mention the keys.

## 6. Order of work (≈ half a day each)
1. Wires: copy sounds + credits → `wire_board.gd` drawing (screenshot) → drag/drop → `wires.gd` rules + cues → finish → register → driver → docs.
2. Valve: copy sounds/model + credits → scene with primitives + shader (screenshot both lights) → `valve.gd` → `TwistHint.restart()` → cues → register → driver → docs.
3. Docs: engineering-log entries in `docs/plan.md` (like the screwdriver's), script TODO lines for the new cues, tick
   "Restore: wires" / "Restore: pipe valve" in `docs/progress.md` with `[review: ...]` notes.

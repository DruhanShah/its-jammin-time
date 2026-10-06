# Plan: Gargoyle quiz (SWITCH_2 obstacle, id `gargoyles`)

Two stone gargoyles guard the switchboard. They argue, promise "riddles", then the lights slam into a game-show look and it turns into a parody of *Who Wants to Be a Millionaire*. Get 3 right in a row and they slide aside. After that the switch opens the valve game. The game is in-world: `SwitchGames.GAMES[&"gargoyles"]` has `scene = ""`, so `power_switch.gd` already disables the switch while it is the current game. All quiz text is placeholder. The models are stand-ins. We do **not** use the show's music, logo, diamond graphics or name: the on-screen title is **"WHO WANTS TO BE A LUMEN-AIRE?"**

## 1. Where they stand (and how they block)

- **Location:** the gargoyles go in the server room's prop tree, as `Rooms/C1/Furniture/GargoyleGate` (an instance of the new scene). `StoryStage._swap_rooms()` moves C1's contents to A3 and mirrors the switch to the **west** wall at local (−5.85, 0, 1), facing east. The gate is only active in SWITCH_2, which is always swapped, so we **author it directly at the west end** and do not add it to `MIRRORED_TO_WEST_WALL`. That means a pre-swap view in the editor shows it next to C1's west doorway, which is harmless because it is hidden there. Add a comment to the scene saying so.
- **Layout (C1 local):** the aisle runs east–west between the rack rows (north fronts at z ≈ −0.82, south fronts at z ≈ 2.82, ends at x ≈ −4.5). The switch is at (−5.85, 1.x, 1).
  - Gargoyle **Gar** stands on a pedestal at (−5.0, 0, −0.1) and **Goyle** at (−5.0, 0, 2.1). Both face east (+X) and flank the switch like temple guardians.
  - Gate origin (−4.4, 0, 1). The `Barrier` StaticBody3D has a BoxShape3D of 0.3 × 2.6 × 3.8 across the aisle (z −0.9…2.9), so the player stops ~1.5 m short of the switch. The switch's Interactable stays disabled anyway.
  - "Hot seat" marker `QuizView` (Marker3D) at (−3.2, 1.6, 1) facing west. The player's view is turned to it when the quiz starts.
- **Visibility by step** (`_sync()` on `_ready` and on `Story.switch_game_changed`):

| State | Gargoyles | Barrier | Interactables |
|---|---|---|---|
| step < SWITCH_2 | hidden | off | off |
| SWITCH_2, `switch_game() == &"gargoyles"` | on pedestals, frozen ("asleep") | **on** | on |
| SWITCH_2 after the gate is beaten, and later steps | stepped aside (end pose), frozen | off | off |

  The "stepped aside" pose is set without tweening on load, so coming back from the valve scene shows them out of the way. Since `GameState.switch_progress` resets with each new step, after SWITCH_2 use `Story.step > SWITCH_2 or progress past gargoyles` for the end state.
- **Off-path nags:** these don't fire, because the player is in the objective's room. `story_stage.objective()` still points at the switch, which is fine.

## 2. Files

```
game/world/office/props/gargoyle_gate/
  gargoyle_gate.tscn / .gd     # the whole in-world game (state machine, barrier, lights rig, audio)
  gargoyle.tscn / .gd          # one statue: model + pedestal + stone material + talk wobble + Interactable
  talk_wobble.gd               # SkeletonModifier3D: wobbles the Head bone while talking ("jaw")
  speech_bubble.gd             # 2D comic balloon that follows a 3D point (camera.unproject_position)
  quiz_ui.tscn / .gd           # CanvasLayer: bottom strip, ladder, timer, lifelines
  quiz_questions.gd            # const QUESTIONS (placeholder data) + const LINES (gargoyle banter)
game/assets/models/gargoyle/    Demon_Mo2ky6vkf8.glb, Demon_LnfIziKv4o.glb, Pedestal_wUeoDKnFBF.glb
game/assets/audio/sfx/quiz/     (sounds, table in §8)
game/narration/quiz_*.tres      narrator cues (subtitle-only placeholders)
```

Small edits to existing code:
- `lighting.gd`: override API (§4).
- `player.gd`: a `frozen` flag (§6).
- `office.tscn`: the instance, plus `Lighting` added to group `office_lighting`.
- `CREDITS.md` files (§8).
- `docs/plan.md` / `progress.md`: log entries.

## 3. Scene trees

```
GargoyleGate (Node3D, gargoyle_gate.gd)
├─ Gar (gargoyle.tscn)  name="GAR", model=Demon_Mo2 (Flying_Idle, Yes, No, Headbutt, HitReact, Punch, Death)
├─ Goyle (gargoyle.tscn) name="GOYLE", model=Demon_Lnf (Idle, Wave, No, Duck, Yes, HitReact, Death)
├─ Barrier (StaticBody3D) └─ CollisionShape3D (Box)
├─ WakeZone (Area3D, mask = player layer, Box ~3 m deep east of the barrier)  # one ambient "psst" line
├─ QuizView (Marker3D)
├─ QuizRig (Node3D, hidden until the quiz)
│   ├─ SpotGar, SpotGoyle (SpotLight3D, magenta, from above, aimed at each statue)
│   ├─ SpotHotSeat (SpotLight3D, cold blue, straight down on QuizView's floor)
│   └─ Sweep (Node3D, AnimationPlayer) └─ SweepA, SweepB (SpotLight3D, purple, rotating cones)
├─ Loop (AudioStreamPlayer3D, bus SFX)   # heartbeat / tension / clock loops, switched by state
└─ QuizUI (quiz_ui.tscn, CanvasLayer layer 5, hidden)

Gargoyle (Node3D, gargoyle.gd)
├─ Pedestal (glb instance, ~1.0 m tall, scaled)
├─ Body (Node3D at the pedestal top) └─ Model (glb, scale ≈ 0.2 so the wingspan is ~1.1 m; Mo2 is ~5.5 units wide)
│     └─ …/Skeleton3D └─ TalkWobble (SkeletonModifier3D)
├─ BubbleAnchor (Marker3D, ~0.4 m above the head)
└─ Interactable (Area3D, verb "talk to the gargoyles", Capsule over pedestal + body, highlight_root ^"../Body")
```

- **Stone look:** in `gargoyle.gd _ready()`, go through the model's meshes and set `surface_override_material` by the source material's `resource_name`:
  - `Demon_Main` → stone grey (0.55, 0.55, 0.52), roughness 0.95. Optionally add a NoiseTexture2D in triplanar for a speckled look.
  - `Black` → dark stone (0.25, 0.25, 0.27).
  - `Eye_White` → grey while asleep; emissive amber (1, 0.7, 0.2) × 3 while awake, magenta during the quiz.
  - `Eye_Black` → black.

  The pedestal's `Marble` material is fine as it is.
- **Asleep:** play `Flying_Idle` / `Idle`, then `seek(0.4)` with `speed_scale = 0`. This gives a frozen statue pose.
- **Awake:** `speed_scale = 0.35`, so the movement looks slow and heavy, like stone.
- **Talk wobble:** a custom `SkeletonModifier3D` (a Godot 4.3+ API; it runs after the AnimationPlayer, so it does not fight it). While `talking`, multiply the `Head` bone's pose rotation by `Quaternion(Vector3.RIGHT, sin(t*22)*0.18)`. Also add a tiny root squash on `Body` (scale y 1 ± 0.03). Both models have `Neck`/`Head`/`Head_end` bones; neither has a jaw.
- **Gestures:** `gargoyle.gesture(&"Yes")` plays a one-shot clip at speed 1, then goes back to the idle loop. Uses:
  - argument: Gar `Headbutt`s Goyle, and Goyle `HitReact`s
  - correct: `Yes`
  - wrong: `No`
  - "final answer?": Goyle `Duck`s for the suspense
  - step aside: Goyle `Wave`

## 4. "The lights suddenly change": lighting.gd override

Add a public API that works on top of the emergency look and does not touch `look`/`LOOKS`, so F6 cycling and the export enum stay clean:

```gdscript
const OVERRIDES := {
  "quiz": {"color": Color(0.25, 0.3, 1.0), "energy": 0.15, "every": 4, "panel_energy": 1.0,
           "env": {"ambient_light_color": Color(0.35, 0.15, 0.55), "ambient_light_energy": 0.08,
                   "fog_light_color": Color(0.25, 0.05, 0.4), "fog_light_energy": 0.35,
                   "glow_intensity": 1.4, "glow_bloom": 0.2}},
}
func set_override(name: String) -> void     # instant (a slam): kill tween, apply OVERRIDES[name] at level 1
func clear_override(fade := 0.4) -> void    # tween back to the current emergency/normal state
```

- **Refactor:** split `_set_emergency(level)` into `_apply(data: Dictionary, level)`, so the same function can apply an override.
- **Env restore:** in `set_override`, record any env keys the override touches that are not already in `_normal_env` or the emergency look, and restore them in `clear_override`.
- **Power changes:** `_on_power_changed` clears any override first. This case shouldn't happen mid-quiz, but it is safe.
- **How the gate finds Lighting:** `get_tree().get_first_node_in_group(&"office_lighting")`. If it is null, the gate falls back to the local rig only.
- **Light count:** 16 lights per object (Compatibility). `every: 4` leaves few ceiling spots on, and the rig adds 5. If the floor shows light popping, drop `SweepB` or switch the sweeps to emissive cones (unlit `CylinderMesh` with additive material) instead of real lights.

**Slam sequence:** `Lighting.set_override("quiz")` with `quiz_lights_slam` → then 0.25 s apart: SpotGar on (slam), SpotGoyle on (slam), SpotHotSeat on → `quiz_intro_hit_horns` → the Sweep animation starts → the QuizUI slides up from the bottom (0.3 s).

**Leaving the quiz:** `Lighting.clear_override()` plus the rig off in reverse order. This happens on a pass or on Esc (walking away).

## 5. Flow / state machine (gargoyle_gate.gd)

`enum State { ASLEEP, BANTER, QUIZ_ASK, QUIZ_LOCKED, QUIZ_REVEAL, PASSED }`

1. **ASLEEP:** entering `WakeZone` the first time shows one bubble: Gar whispers *"Psst. Goyle. Customer."* (eyes flicker). X on either statue → `BANTER`.
2. **BANTER** (player frozen, mouse still captured, Space/X/click to advance or auto-advance after a reading time): play `LINES.intro`. The last line triggers the slam (§4) → `QUIZ_ASK`.
3. **QUIZ_ASK:**
   - Release the mouse (`MOUSE_MODE_VISIBLE`, `ComicCursor.apply()`) and turn the view toward `QuizView` (tween the player's yaw/pitch, 0.4 s).
   - Pick the next question from a shuffled deck, drawn without repeats and reshuffled when empty.
   - `Audio.play_music(think_loop)`, which ducks under the narrator for free.
   - The "timer" starts showing random numbers.
   - The player picks with a click or **1–4 / A–D**. That highlights the option orange, and Goyle's bubble says *"Is that your final answer?"*. A second click on the same option, **Enter**, or the `FINAL ANSWER` button locks it in. Picking a different option just moves the highlight.
4. **QUIZ_LOCKED:**
   - `quiz_final_answer_boom`, stop the music, start the heartbeat loop.
   - Hold for 1.5–3 s, random. During the hold the gargoyles lean in and Goyle `Duck`s. The timer shows `???`.
5. **QUIZ_REVEAL:**
   - **Correct:** green flash + `quiz_correct`, Gar `Yes`, `streak += 1`, ladder steps up. If `streak == 3` → PASSED, else back to QUIZ_ASK.
   - **Wrong:**
     - `quiz_wrong_buzzer`; the correct option flashes green and the chosen one red.
     - Penalty gag: the ladder drops to the bottom with a `ComicBurst "WRONG!"` (red), `streak = 0`, and both statues `No`. Room lights flicker once: `set_override` off/on twice in 0.2 s.
     - A rotating snark line plays (bubble). After every 2 misses a narrator cue plays (`quiz_wrong_N`).
     - Back to QUIZ_ASK.
6. **Esc during the quiz** = walk away: confirm with *"Leaving? You'd forfeit your… nothing."*, then restore the lights, music, mouse and player. The streak is kept (it's a gag; nobody will notice). X again resumes straight from the slam and skips the banter.
7. **PASSED:**
   - `clear_override(0.6)`; `quiz_correct_harp`; final bubble lines; the UI slides down; the player is unfrozen and the mouse recaptured.
   - Step aside: `stone_grind_heavy` and a short rumble. Each statue + pedestal tweens 1.3 m outward in z (Gar to −1.4, Goyle to 3.4; this space exists, because the racks end at x −4.5) and turns 90° to face the switch. Goyle `Wave`s.
   - Barrier off, Interactables off.
   - `Story.switch_game_done(&"gargoyles")`. That emits `switch_game_changed`, and `power_switch._sync()` enables the switch with the `valve` verb (placeholder scene).
   - `Narrator.play(&"quiz_passed")`.

### "Timer that keeps showing random numbers"
This is a round dial above the strip's centre (custom `_draw`: ring + arc). Every 0.6–1.1 s it jumps to a random entry from a pool, with a `pack_clock_tick_only` tick and the clock ticking loop under it:
- `30` `7` `29` `-4` `3.14` `812` `0` `∞` `NaN` `12:00` `BEES` `½` `π²` `69,105` `ERROR` `LOL`

The arc length is also random. Showing `0` does nothing, and Gar says *"The clock is decorative."* (once).

### Quiz UI (quiz_ui.tscn, comic kit style)
- **Theme:** the project's Comic theme. Thick black outlines, offset shadows, Comic Relief Bold for headings, Comic Neue for answers. Colours are navy/purple with gold borders, a nod to the show without copying its graphics.
- **Bottom strip (anchored bottom, ~32% of the height):**
  - a question bar across the top, with a pointed hexagon ends drawn as a `StyleBoxFlat` with skew or a `_draw` polygon
  - a 2 × 2 grid of answer buttons `A:` `B:` `C:` `D:` (states: normal / selected orange / correct green / wrong red / disabled)
  - a `FINAL ANSWER` button
- **Ladder (right column):** 3 rungs + floor: `0 — Nothing (a firm stare)`, `1 — 100 lumens`, `2 — 1,000 lumens`, `3 — ACCESS TO THE SWITCHBOARD`. The current rung is gold, and the next one blinks.
- **Lifelines (top right; optional, each usable once):**
  - **50:50** removes two wrong answers, then the two left swap letters.
  - **Phone a Friend** plays a ring sfx and then `Narrator.play(&"quiz_phone_friend")`: *"I'm not your friend. I'm the narrator. Pick B. Or don't. I'm contractually neutral."*
  - **Ask the Audience** shows 4 bars at exactly 25% each, labelled "Audience: 1 sleepy fan (the cooling fan)".
- `quiz_ui.gd` has the signals `answer_selected(i)`, `answer_locked(i)`, `lifeline_used(name)`, `walk_away` and the methods `show_question(q)`, `reveal(correct_i, chosen_i)`, `set_streak(n)`, `slide_in()`, `slide_out()`.

## 6. Input, mouse, player freeze

- `player.gd`: add `var frozen := false`. When it is true:
  - `_physics_process` applies gravity only and ignores the movement input.
  - `_unhandled_input` skips mouse look, interact, touch and the "click to recapture" branch. Esc is left to the gate, so the quiz handles `ui_cancel` first with `_input` + `set_input_as_handled()`.
  - The HUD prompt and crosshair are hidden (`hud.visible = false` while frozen).
- The gate finds the player with `get_tree().get_first_node_in_group(&"player")`. If the group is missing, add it.
  - Quiz start: freeze → turn the view → `Input.mouse_mode = MOUSE_MODE_VISIBLE` → `ComicCursor.apply()`.
  - Quiz end: `ComicCursor.reset()` → captured → unfreeze.
- **Keys:** the quiz handles 1–4 / A–D / Enter in `_unhandled_input` while it is visible. The A/D/W/S movement keys are harmless while frozen. Buttons use `mouse_default_cursor_shape = POINTING_HAND`. `focus_mode = NONE` stops Space/Enter from re-triggering a focused button.
- **Banter advance:** X / Space / left-click. Each line also auto-advances after `max(1.6, chars/15)` s, matching the Narrator's reading speed.

## 7. Dialogue (speech bubbles, not Narrator subtitles)

The Narrator is a single voice with one bottom subtitle label and no speaker field. Keep it as **the narrator only**. The gargoyles talk in **comic speech balloons** (`speech_bubble.gd`):
- a Control on the QuizUI CanvasLayer (or its own layer when the UI is hidden), positioned each frame at `camera.unproject_position(BubbleAnchor)` with a tail toward the head, and hidden if the anchor is behind the camera
- off-white paper, black outline, name tag "GAR" / "GOYLE" in Comic Relief Bold
- while a balloon is up, the matching statue's `talking = true` (wobble) and a soft stone-tick blip plays per word (`pack_stone_push_short`, pitch-randomised, -18 dB)

The narrator still gets a few cues (`quiz_*`) between beats. Never put a cue on top of an open balloon. Bubbles wait for `Narrator.is_speaking()` to be false.

**Banter (`LINES.intro`), placeholder:**
- GAR: Halt! None shall pass… without answering three riddles.
- GOYLE: Three? We agreed on two. Two is classier.
- GAR: Two is a *pair*, Goyle. Riddles come in threes. It's in the guild handbook.
- GOYLE: The guild handbook is a napkin, Gar.
- GAR: (headbutts) A *laminated* napkin. Ahem. Riddle one: what has keys but can't open locks?
- GOYLE: A piano. Everybody knows it's a piano. Management says riddles are "low engagement".
- GAR: …Fine. We've been rebranded.
- BOTH: **LIGHTS!** → slam

**Reactions (pick at random):**
- *Correct:* "Lucky." / "The guild will hear of this." / "Don't get cocky, fleshling." / "That's… technically right, the worst kind of right."
- *Wrong:* "Ooh. Rock bottom. We'd know." / "Back to zero, sweetie." / "I've seen gravel with more sense." / "We have all night. We literally cannot leave."
- *Pass:* GOYLE "Three in a row. Ugh. Fine." · GAR "Go. Flip your little switch." · GOYLE "Tip your gargoyles!" → grind.

**Narrator cues** (subtitle-only `.tres`, placeholders): `quiz_start` ("Ah, prime time."), `quiz_wrong_1`/`_2`, `quiz_phone_friend`, `quiz_passed` ("Congratulations. You've won: the same switch you've flipped twice already.").

## 8. Placeholder questions (`quiz_questions.gd`, the ★ option is correct)

Format: `{q = "…", a = ["…","…","…","…"], correct = i}`. Answers are shuffled at display time, and `correct` follows the shuffle.

1. What do you call a gargoyle who tells jokes? — Stand-up rock ★ · A boulder comedian · Sedimental · Gary
2. How many lumens does it take to change a light bulb? — None, it's a power cut ★ · 3 · Blue · Ask the switchboard
3. Which of these is NOT a font? — Comic Sans · Comic Neue · Comic Relief · Comic Tragedy ★
4. What's the quickest way to fix a blackout? — Wait for daylight · Turn it off and on again ★ · Shout · Blame IT
5. What comes next: 1, 2, 3, … — 4 · 3 · Ah, ah, ah! (count it with a vampire voice) · Riddle three ★
6. Twist: what's the answer to this question? — This one · Not this one · The previous one · ALL OF THE ABOVE ★ (all four light up green as a gag; only D actually counts)
7. Which is heavier: a kilo of feathers or a kilo of gargoyle? — Feathers · Gargoyle · Same ★ · Don't weigh us, it's rude
8. Why did the employee bring a ladder to the office? — To reach the high-paying job · To get to the next level ★ (the ladder lights up) · For the ceiling lights · Fire drill
9. Click the smallest answer. — **HUGE** · a ★ (tiny text) · medium · Large-ish
10. What is Goyle's favourite music? — Rock ★ · Rock · Rock · Heavy metal (the first "Rock" is right; the other two are "the wrong kind of Rock". Wrong-answer line: *"That was the wrong Rock."*)

Deck rule: shuffle; 3 correct in a row needs ≥ 3 different questions, so the deck never repeats inside a streak. If the deck runs out, reshuffle but don't repeat the last question.

## 9. Assets and credits

**Models:** copy to `game/assets/models/gargoyle/`.
- Demon (×2 variants) by **Quaternius**, CC0: https://poly.pizza/m/Mo2ky6vkf8 and https://poly.pizza/m/LnfIziKv4o
- Pedestal by **Quaternius**, CC0: https://poly.pizza/m/wUeoDKnFBF

On import: root scale 1, scaled in `gargoyle.tscn`. Leave the animations as they are; set loop mode on `Flying_Idle`/`Idle` in the import dialog's animation settings.

**Sounds:** copy to `game/assets/audio/sfx/quiz/`, set WAV loop mode Forward on the `*_loop` files. All are Freesound CC0 unless marked.

| Use | File | Credit |
|---|---|---|
| Think music | quiz_think_loop_portwain.wav | "quiz game music loop BPM 90" by portwain, freesound.org/s/220060 |
| Locked-in suspense | quiz_heartbeat_loop_loudernoises.wav | "heartbeat-60bpm" by loudernoises, /332821 |
| Banter undertone (optional) | quiz_tension_drone_loop_gerainsan.wav | "Horror Pulsating Drone Loop" by gerainsan, /457046 |
| Light slam | quiz_lights_slam_grubzyy.wav | "S_Spotlight_On" by Grubzyy, /422736 |
| Final answer | quiz_final_answer_boom_harrisonlace.wav | "DSGNStngr_basic trailer boom impact" by harrisonlace, /816376 |
| Correct | quiz_correct_bwg2020.wav | "Correct.wav" by bwg2020, /456161 |
| Pass (optional) | quiz_correct_harp_oggraphics.wav | "Good answer harp glissando" by oggraphics, /610703 |
| Wrong | quiz_wrong_buzzer_kevinvg207.wav | "Wrong Buzzer" by KevinVG207, /331912 |
| Quiz intro | quiz_intro_hit_horns_devern.wav | "Cinematic Hit With Horns" by DeVern, /427803 |
| Timer | pack_clock_ticking_loop.wav, pack_clock_tick_only.wav | 400 Sounds Pack, Chequered Ink (already credited; add the filenames) |
| Step aside | stone_grind_heavy_postproddog.wav | "Heavy stone door opens 2" by PostProdDog, /578491 |
| Step aside (alt) / wake | stone_grind_long_kinoton.wav | "Tomb Door Open, Stone Scrape" by Kinoton, /352829 |
| Rumble | rumble_swell_unfa.wav | "Rumble · fade in 10s" by unfa, /258341 (trim to ~2 s fade-out in code) |
| Word blips | pack_stone_push_short.wav | 400 Sounds Pack |

Add the rows to `game/assets/audio/CREDITS.md` and `game/CREDITS.md` (with the models), in the existing format. The full meta is in the scratchpad `audio2/meta.json` / `assets3d/CREDITS.tsv`. The CC-BY pulpit and Goat Devil are **not** used. The podium, if wanted as the "host desk" in front of the gargoyles, is built from primitives: a `CSGCylinder` (8 sides, r 0.35, h 1.0) plus a slanted top `CSGBox`, with a purple emissive strip.

## 10. Test plan

- **F7 to SWITCH_2 → office loads swapped and dark.** Walk A2 → A3 north door → aisle.
  - The gargoyles are visible and you can't walk past them.
  - The switch prompt doesn't show.
  - The `WakeZone` "psst" line plays once.
- **Banter:** balloons follow the heads, wobble while talking, and auto-advance. The narrator never overlaps a balloon.
- **The slam:** the lights change instantly, the rig spots come on one by one, and the UI slides up. Mouse visible with the glove cursor. WASD/mouse-look do nothing, and clicking empty space doesn't recapture.
- **Quiz:**
  - selecting, re-selecting and locking in work (click / 1–4 / A–D / Enter)
  - wrong resets the ladder to 0
  - 3 correct in a row passes; check that 2 right + 1 wrong + 3 right needs the full 3 again
  - the timer keeps changing and shows `???` while locked
  - lifelines each work once
- **Esc mid-quiz:** the lights, music, cursor and control are restored. X again resumes.
- **Pass:**
  - the statues slide aside with the grind
  - the barrier is gone
  - the switch prompt reads "Press X to turn the valve"
  - X → valve placeholder → back in the office, where the statues are still aside, the barrier is off, and the player pose is restored
- **SWITCH_3 (F7 on):** the statues are aside and inert. **INTRO/SWITCH_1:** not visible, and C1's west doorway is passable.
- **Screenshots** (save to `docs/map/screenshots/gargoyles/`): `normal.png` (power on, F5, statues hidden or aside), `emergency.png` (SWITCH_2, approach), `quiz_light.png` (mid-quiz, UI up), `passed.png`. Check the light count: there should be no flickering light popping on the floor in `quiz_light.png`.
- Game log: no errors. Web build: the quiz audio plays (no bus effects needed).

## 11. Risks

- **Light limit** (16 per object, Compatibility): the quiz rig plus the remaining ceiling spots on the floor mesh. Mitigations: `every: 4`, hide most office spots in the override, or fake the sweeps with emissive cones.
- **Model scale/orientation:** these are Quaternius FBX→glb. The wingspan is ~5.5 units at an unknown up-axis/facing, so measure the AABB in the editor and fix it in `gargoyle.tscn`, not in code. The flying idle has the feet off the ground, so offset `Body` y so it "perches".
- **Recolour by material name** breaks if the import renames materials. Fallback: override every surface with stone and the eye surfaces by index.
- **SkeletonModifier3D** needs the right Godot 4.7 API (`_process_modification_with_delta`). Fallback: rotate the `Body` node (head-bob by whole body), which is good enough for a stand-in.
- **Mouse/freeze leaks:** a scene change mid-quiz (e.g. F7) must not leave the player frozen. The player is rebuilt with the scene, so only `Input.mouse_mode` and the custom cursor need resetting. Do that in the gate's `_exit_tree()`. The lighting override dies with the scene.
- **Audio.play_music** replaces any future office music. Save `Audio.music.stream` before and restore it after.
- **The swap mirrors only listed paths.** If someone later moves the gate into `MIRRORED_TO_WEST_WALL`, it will flip back to the east wall. The authoring note in the scene covers this.
- **Show likeness:** keep our own title, colours and sounds (all CC0, none from the show) and the "Lumen-aire" parody wording.

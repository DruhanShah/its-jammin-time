# Progress

Task checklist for the game, updated as each task starts and finishes. The game design and ideas live in [plan.md](plan.md).

Legend: `[ ]` todo · `[~]` in progress · `[x]` done (awaiting review notes in brackets)

## Done
- [x] Godot project setup, folder structure, `.gitignore`
- [x] VNB office asset pack imported (shared materials, generated collision)
- [x] Office room: floor, walls, ceiling, cold-blue ceiling lights, SSAO
- [x] First-person player: WASD, mouse look, head bob, collision
- [x] godot-ai MCP addon (export strips its autoload automatically)

## Current: 3D roaming improvements
- [x] Tutorial: placing asset objects in the map (`docs/tutorials/placing-assets.md`) [review: macOS shortcuts not verified on 4.7]
- [x] (e) Sound system: audio buses, SFX player, looping background music, footsteps [review: `core/audio/audio.gd`, footstep timing in `player.gd`]
- [x] (a) Narrator cue system: play cues from game-state triggers + placeable trigger area [review: `core/narrator/narrator.gd` play()]
- [x] (f) Subtitles shown with narrator lines (Comic Neue Italic) [review: `core/narrator/narrator.tscn`]
- [x] (b) Object interaction: "Press X to interact" when close, sends to a placeholder minigame scene [review: `core/interaction/interactable.gd`, `player.gd` input handling]
- [x] (c) Crosshair at screen centre [review: `core/player/hud.tscn`]
- [x] (d) Placeholder cuboid hands; left click tries to touch objects [review: `core/player/hands.gd`]

## Current: approved polish
- [x] Remember player position/rotation when returning from a minigame [review: `core/game_state.gd`, `player.gd` `_ready`/`_exit_tree`]
- [x] Hide subtitles on scene change (the line stops too) [review: `narrator.gd` `stop()`/`_on_scene_changed()`]
- [x] Lower the music while the narrator speaks [review: `audio.gd` `_duck_music()`]
- [x] Build the interact prompt from the current key binding [review: `hud.gd` `key_name()`, `interactable.gd` `verb`]

## Current: editor tooling
- [x] `Furniture` group in `office.tscn` (desk + computer moved into it)
- [x] Plugins: Godot Asset Placer 1.6.0, godot-snappy (usage in `docs/tutorials/placing-assets.md`)
- [x] Audio keeps playing while the game is paused
- [x] GridMap MeshLibrary for wall/floor/door pieces; floor + walls are now GridMaps [review: `world/office/gridmap/`, tutorial section]
- [x] Trimesh (exact) collision for floor, wall and static furniture imports (was already the default; now pinned)
- [x] Exclude editor-only addons from exported builds (macOS export preset, verified with a test pack)
- [x] Shared Asset Placer library committed in the repo (`assets/asset_placer_library.json`)
- [x] Sound effects from "400 Sounds Pack" (ci.itch.io) replacing placeholders [review: listen to volumes]
- [x] Central credits file listing every external resource (`game/CREDITS.md`)
- [x] Subtitle-only narrator cues (shown for max(2 s, chars/15)) [review: `narrator.gd` play()]
- [x] Interactable `enabled` flag [review: `player.gd` `_interactable()`]
- [x] Fade transition into/out of minigames (`Transition.change_scene`) [review: `core/transition/transition.gd`]
- [x] Global unlocks in `GameState` (interactables available at different times, not tied to a scene) [review: `interactable.gd` `is_usable()`, `game_state.gd`]
## Current: office map (from `docs/map/layout_sketch.jpeg`)
- [x] Phase 1: room shells: 10 rooms ~2× bigger and rectangular, doors between adjacent rooms, ceilings, lights [review: confirm layout from `docs/map/layout_topdown.png`; `docs/map/README.md`]
- [x] Furnishing research: `docs/map/furnishing_guide.md` (inventory, workstation recipes, weirdness ladder)
- [~] Phase 2: furnishing (desk counts per room, server room with giant/stacked PCs as fake mainframes, weird paintings, C2 fully upside down (all furniture on the ceiling), odd placements further from start)

- [x] Pushable chairs (walk into them to push them around) — a chair prop scene used when furnishing [review: `world/office/props/office_chair.tscn`/`.gd`, `player.gd` `_push_bodies()`; walk into the chair at your desk]
- [x] Chair wheels rolling sound found: "rolling_office_chair.WAV" by alpanaytekin (Freesound 213086, CC0), cut into a 3.0 s loop (user's pick); added with the pushable chairs
- [x] First-person arms from "PSX First Person Arms" (drillimpact.itch.io, CC0) replacing cuboid hands, with a grab animation on touch and interact [review: `core/player/hands.tscn`/`.gd`; left click the desk, press X at the computer, stand against a wall]

- [x] Arms polish: left hand stays still during a grab, push animation on chairs, arm sway, left-hand grab for targets on the left [review: `core/player/hands.tscn` AnimationTree, `hands.gd`; click at things, X at something left of the crosshair, walk into a chair, turn quickly]
## Up next (in this order)
- [x] Interaction batch: locked objects show a prompt and the narrator mocks you; subtle highlight on the targeted object; unlock ids as constants in one place (internal only) [review: `core/interaction/interactable.gd`, `highlight.gdshader`, `core/unlocks.gd`, `narration/locked_*.tres`; set the computer's `unlock_id` to `genie_lamp`, aim at it and press X]
- [x] Doors: frame + openable door in every doorway (X to open/close, door sound); A2's door to nowhere and B1's corridor doors use it too [review: `world/office/props/door.tscn`/`door.gd`, `docs/map/screenshots/door_*.png`; open the Start door from both sides, walk B1's corridor, open A2's fake door, stand in a doorway and close the door on yourself]
- [x] Furnishing 1/2: prefab sets + Start, A1–A3, B1–B3; B1 lights moved onto the walls [review: `docs/map/screenshots/` (`<room>.png` from a doorway, `<room>_top.png` top-down with north on the left), deviations at the end of `docs/map/furnishing_plan.md`; walk A2 → B1, push a chair]
- [x] Furnishing 2/2: C1 server room (amber lights, flicker), C2 upside-down, C3 [review: `docs/map/screenshots/c1*.png`, `c2*.png`, `c3*.png`; deviations in "As built (part 2)" at the end of `docs/map/furnishing_plan.md`; walk B1 → C1 aisle → switchboard spot, look up in C2, push C2's floor chair]
- [x] Chairs: bump/squeak sound on hitting walls; narrator jab after pushing chairs for a while (lines needed in script) [review: `world/office/props/office_chair.gd`, `narration/chair_push_1/2.tres`; shove a chair into a wall slowly and fast, pin one against a wall, roll chairs around for the squeak, push chairs for 15 s / 45 s]
- [x] Third chair jab: narrator line when you push a chair into another room [review: `core/player/player.gd` (`_check_chair_rooms`, `_room_at`), `narration/chair_new_room.tres`; push a chair from Start through the door into A2]
- [x] "Lights went out" phase: dimmer emergency lighting; try neon-ish vs red, pick what still reads as an office and shows off the map (comparison screenshots for the user) [review: `docs/map/screenshots/lights_out/comparison.png` (normal / A neon / B red / C mix, recommended + default); pick with `Lighting.look` in office.tscn; in game F5 toggles the power, F6 cycles the looks (debug builds only); `world/office/lighting.gd`, `GameState.set_power()`]

## Current: teammate code + story flow
- [x] Integrate teammate's `computer-minigames` branch (computer screen, ad popup, corporate speak, captcha) on branch `integrate/computer-minigames` (not in master yet): office computer opens the computer screen, Power returns to the desk, story API `Computer.open()`/`queue()` + `GameState.computer_minigame_finished`/`computer_queue_finished` [review: `minigames/computer/event_manager.gd`, `computer.gd` `open()`/`queue()`/`exit()`, `core/game_state.gd`; X at the desk, play memo → ad → bot check, press Power]
- [x] Comic font family: research licenses, add usable fonts to the game + credits (Comic Sans MS itself not usable: Microsoft licence) [review: `core/ui/theme.tres` (project theme, `gui/theme/custom`), `assets/fonts/CREDITS.md`, `CREDITS.md`; check the HUD prompt, a subtitle, the computer screen, signs in B2/C1 and EXIT signs (F5)]
- [x] Story flow: start at the computer minigame → lights out → server room switch → back → minigame 2 → lights out, server room swapped with A3 → switch there → minigame 3 → lights out → switch again [review: `core/story.gd` (steps, `FIRST/SECOND/THIRD_VISIT` minigame lists), `world/office/story_stage.gd` (`_swap_rooms`), `docs/map/screenshots/story/`; play from the start, F7 skips a step (debug builds)]
- [x] Switch = highlighted interactable that opens a placeholder switch minigame (real switch minigames later) [review: `world/office/props/power_switch.tscn`, `minigames/switch/switch_minigame.tscn`; press X on it with the lights on (locked line) and off]
- [x] Off-path narrator: cues when the player wanders away from the current objective for a while [review: heuristic in `story_stage.gd` header, `off_path_time` 25 s / `off_path_cooldown` 30 s on the `StoryStage` node; lines `narration/off_path_1..4.tres`]

## Computer screen (teammate, `computer-minigames` branch)
- [x] Computer scene (`minigames/computer/computer.tscn`): vim-ish editor (insert mode only), Power button exits back to the office [review: `computer.gd` `start_minigame()`/`exit()`]
- [x] Modular minigame framework: `Minigame` base, `MinigameConfig` tunables, `minigame_registry.tres` [review: `minigame.gd`]
- [x] Event manager stub: plays minigames one after another (story queue in `GameState.computer_queue`, else `start_on_open`), retries a failed one; to be replaced by the real event system [review: `event_manager.gd`]
- [x] Minigame: pop-up ad with a tiny X (decoy spawns more ads, X dodges after 3 closes) [review: tune in `ad_popup_default.tres`]
- [x] Minigame: corporate-speak memo, fill each blank with the most corporate word; per-word points go to a shared score in the status bar [review: sentences in `corporate_speak_default.tres`, syntax `{word:points|word:points}`]
- [x] Minigame: bot check, a "click me if you are a bot" trap button (fail, score penalty), an "I'm not a robot" captcha that passes after a random number of tries (5% first try), and a close X that appears after 3s [review: tune in `bot_check_default.tres`]
- [x] Shared score: `Computer.add_score()` → `GameState.score`, shown in the status bar
- [ ] Real event manager (timings for every minigame)
- [ ] Vim modes (normal/insert, Esc)
- [ ] Minigames: floating letters, password scream

## Maintenance
- [~] Fix all Godot editor/game errors (e.g. recurring "Identifier not found: GameState/Audio/Narrator" on script reload, twist_demo parse error)

## Fixes
- [x] Remove the big-text signs in the server room (SERVER ROOM, LEGACY / DO NOT TOUCH, DAYS SINCE LAST BLACKOUT) and the green EXIT signs from the lights-out look; keep the other signs
- [x] Pushing a chair behind you shouldn't trigger the push arm animation (only when the chair is in front)

## Computer redesign
- [x] Brainstorm (awaiting approval): make computer minigames comic-ier and more fun; fake desktop instead of terminal (`docs/computer_redesign.md`)
- [~] Visit 1 part A: comic window kit, Computer.blackout(), mic password (building on teammate Kimaya's `password_scream`)
    - [x] Comic UI kit: `AppWindow` (outline, title bar, X, squash-and-stretch, POOF! burst), halftone shader, glove cursor [review: `core/ui/comic/`; open the computer, watch the login window pop in]
    - [x] `Computer.blackout()`: flicker + CRT-off from the computer, the office loads already dark with `lights_out_1` (no second delayed cut) [review: `computer.gd` `blackout()`, `story.gd` `_on_computer_queue_finished`/`_on_power_changed`, `story_stage.gd` `_blackout()`]
    - [~] VoiceLogin on top of `password_scream` (live waveform, 2 scripted fails, silence timeout, fake waveform, text box, in an AppWindow): built and tested in an isolated copy, waiting for the `git pull` of the teammate's `password_scream` (needs the user's OK) before it lands; then `FIRST_VISIT = [password_scream, corporate_speak]`
    - [x] Export: macOS mic usage text + `audio_input` entitlement; Web preset (no threads) for itch.io
- [ ] Visit 1 part B: font picker, ad storm (ECO MODE ad causes the blackout), wire FIRST_VISIT
- [ ] Visit 1 (approved design): password via fake mic (live waveform, fails 2×, then text box) → font picker (must be Comic) → typing triggers ads → all closed → lights out

- [ ] Visit 2 (approved design): software_update → memo_mail → inky
- [ ] Visit 3: redo — 3 concepts in `docs/computer_redesign.md` §8 (recommended: LightGuard), awaiting user pick
- [ ] Side monitor in computer mode (waiting for user's media)

## Switchboard gauntlet (twist minigames)
- [x] Asset search: 3D models — picks in scratchpad `assets3d/` (Poly Pizza CC0/CC-BY; no free non-AI gargoyle → recoloured Quaternius demons on pedestals)
- [x] Asset search: sounds — 71 picks in scratchpad `audio2/out/` (Freesound CC0, Kenney CC0, 400 Sounds Pack); quiz loop mood needs a listen
- [x] Twist input detector: B-H-Y-T-F-V circle around G (direction + amount), reusable
- [x] Switchboard framework: obstacle then restore minigame per blackout, wired into the story flow [review: `core/story.gd` (`SWITCH_GAMES`, `switch_game()`/`switch_game_done()`/`next_switch_scene()`), `minigames/switch/switch_games.gd`, `world/office/props/power_switch.gd`; F7 to SWITCH_1, X on the switch, leave mid-pair with Esc and come back]
- [x] Obstacle: screwdriver panel (3 screws + a sticker gag) [review: `minigames/switch/screwdriver/screwdriver.gd`/`.tscn`, tune `turns_per_screw`/`back_out`/`sticker_degrees`; lines `narration/screwdriver_*.tres`; listen to the click/drop/clatter volumes]
- [x] Twist teaching hint: reusable key-ring widget with demo, live feedback, shrinks once mastered, returns on stall + first-time narrator line [review: `core/input/twist_hint.gd`/`.tscn`, `narration/twist_tutorial.tres`]
- [ ] Obstacle: gargoyle riddle → Millionaire quiz (dialogue, lighting change, sfx, 3 in a row, random-number timer)
- [ ] Obstacle: kaleidoscope + "TWIST ME" painting → password for the switchboard keypad
- [ ] Restore: wires (connect straight, not by colour) + narrator mockery
- [ ] Restore: pipe valve
- [ ] Restore: candle wick
- [ ] After the third blackout: controls shift to ESDF + narration
- [~] Teach the twist control: reusable key-ring hint (demo animation, live feedback) used by every twist game

- [ ] Web (HTML5) export for itch.io: preset, mic permission in itch's iframe, test the whole game in a browser (performance with ~117 lights in WebGL2, Jolt, audio)
- [ ] Before first export: change placeholder bundle id `com.infinium.gamejam` in `export_presets.cfg`

## Conventions
- Computer minigames live in `minigames/computer/minigames/<name>/`: a scene whose root extends `Minigame`, a `MinigameConfig` subclass + default `.tres`, and one line in `minigame_registry.tres`. Minigames never decide when they start; the event manager calls `Computer.start_minigame(id, overrides)`; the story picks them with `Computer.open(ids)` / `Computer.queue(ids)`
- Interactive props are wrapper scenes in `world/office/props/` (Node3D root + model + Interactable/script), made when the mechanic is built

## Suggestions awaiting approval
- Story: per-objective off-path lines ("the desk is the other way") and a short hint line when the off-path count runs out
- Story: a power-down clunk + fluorescent tick sound on the blackout / switch
- Story: `NarratorTrigger` option to not interrupt a line (the desk trigger's `desk_intro` can cut a story line short)
- Story: tiny map/compass on the HUD while the lights are out
- Computer: keep the typed document (`buffer`) in `GameState` so it survives leaving the computer
- Computer: root as a full-rect Control instead of Node2D + `_fit_screen()`
- Computer: narrator lines per minigame (bot button, 3rd ad, captcha retries)
- Lights out: a power-down/up sound (clunk + fluorescent tick) and a narrator line on the blackout
- Lights out: emergency fixtures stutter for a second when they kick in (reuse `light_flicker.gd`)
- Lights out: C1 keeps a few amber lights on the "generator" while the rest of the office is dark
- Chairs: only the faster chair bumps in chair-on-chair hits; 2–3 bump variants
- Door: ease-out at the end of the swing; bump sound when blocked
- Narrator lines when opening A2's fake door / B1's last door onto bare wall
- Soft "denied" thunk sound when pressing X on a locked object
- Locked lines don't repeat back-to-back; get sharper after several tries
- Prompt verb changes while locked ("try to use the computer")
- Stronger highlight option for small/dark props
- Panelled walls in some rooms
- Set unlocks from the Inspector: `unlock_id` on NarratorTrigger, `unlocks_on_interact` on Interactable
- Save unlocks to disk once there's a save system
- `Transition.fade_out()`/`fade_in()` for cutscenes without a scene change
- Instant cut (skip the fade) as a narrator gag
- Chained cues (one line starts the next) — only needed for waits/conditions between lines
- Positional 3D sound effects (`play_sfx_3d`)
- Different footstep sounds per floor surface
- Subtitles on/off setting
- A size property on narrator triggers that can be edited in the editor
- Placeholder minigame text uses the current interact key instead of "Esc or X"
- `GameState.reset()` for new game / restart
- Per-cue music ducking amount
- Narrator cues that keep playing across scene changes (`persist` flag)
- Fade subtitles out instead of hiding instantly

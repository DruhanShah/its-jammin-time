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
- [x] (f) Subtitles shown with narrator lines (Comic Neue font) [review: `core/narrator/narrator.tscn`]
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
- [ ] Doors: frame + openable door in every doorway (X to open/close, door sound)
- [x] Furnishing 1/2: prefab sets + Start, A1–A3, B1–B3; B1 lights moved onto the walls [review: `docs/map/screenshots/` (`<room>.png` from a doorway, `<room>_top.png` top-down with north on the left), deviations at the end of `docs/map/furnishing_plan.md`; walk A2 → B1, push a chair]
- [x] Furnishing 2/2: C1 server room (amber lights, flicker), C2 upside-down, C3 [review: `docs/map/screenshots/c1*.png`, `c2*.png`, `c3*.png`; deviations in "As built (part 2)" at the end of `docs/map/furnishing_plan.md`; walk B1 → C1 aisle → switchboard spot, look up in C2, push C2's floor chair]
- [ ] Chairs: bump/squeak sound on hitting walls; narrator jab after pushing chairs for a while (lines needed in script)
- [ ] "Lights went out" phase: dimmer emergency lighting; try neon-ish vs red, pick what still reads as an office and shows off the map (comparison screenshots for the user)

- [ ] Before first export: change placeholder bundle id `com.infinium.gamejam` in `export_presets.cfg`

## Conventions
- Interactive props are wrapper scenes in `world/office/props/` (Node3D root + model + Interactable/script), made when the mechanic is built

## Suggestions awaiting approval
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

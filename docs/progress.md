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
- [ ] Before first export: change placeholder bundle id `com.infinium.gamejam` in `export_presets.cfg`

## Conventions
- Interactive props are wrapper scenes in `world/office/props/` (Node3D root + model + Interactable/script), made when the mechanic is built

## Suggestions awaiting approval
- Set unlocks from the Inspector: `unlock_id` on NarratorTrigger, `unlocks_on_interact` on Interactable
- Locked objects show a prompt + narrator jab instead of being hidden
- Unlock ids as constants in one place (avoid typos)
- Save unlocks to disk once there's a save system
- `Transition.fade_out()`/`fade_in()` for cutscenes without a scene change
- Instant cut (skip the fade) as a narrator gag
- Paint the ceiling with a third GridMap
- Chained cues (one line starts the next) — only needed for waits/conditions between lines
- Positional 3D sound effects (`play_sfx_3d`)
- Different footstep sounds per floor surface
- Subtitles on/off setting
- A size property on narrator triggers that can be edited in the editor
- Outline/highlight on the targeted object
- Alternate hands per click
- Placeholder minigame text uses the current interact key instead of "Esc or X"
- `GameState.reset()` for new game / restart
- Per-cue music ducking amount
- Narrator cues that keep playing across scene changes (`persist` flag)
- Fade subtitles out instead of hiding instantly

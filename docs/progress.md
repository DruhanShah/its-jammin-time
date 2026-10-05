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
- [ ] Subtitle-only narrator cues
- [ ] Interactable `enabled` flag
- [ ] Scene transition into/out of minigames (style to be decided)

## Current: computer screen
- [x] Computer scene (`minigames/computer/computer.tscn`): vim-ish editor (insert mode only), Power button exits back to the office [review: `computer.gd` `start_minigame()`/`exit()`]
- [x] Modular minigame framework: `Minigame` base, `MinigameConfig` tunables, `minigame_registry.tres` [review: `minigame.gd`]
- [x] Event manager stub: starts the ad straight away; to be replaced by the real event system [review: `event_manager.gd`]
- [x] Minigame: pop-up ad with a tiny X (decoy spawns more ads, X dodges after 3 closes) [review: tune in `ad_popup_default.tres`]
- [x] Minigame: corporate-speak memo, fill each blank with the most corporate word; per-word points go to a shared score in the status bar [review: sentences in `corporate_speak_default.tres`, syntax `{word:points|word:points}`]
- [x] Minigame: bot check, a "click me if you are a bot" trap button (fail, score penalty), an "I'm not a robot" captcha that passes after a random number of tries (5% first try), and a close X that appears after 3s [review: tune in `bot_check_default.tres`]
- [x] Shared score: `Computer.add_score()` → `GameState.score`, shown in the status bar
- [ ] Real event manager (timings for every minigame)
- [ ] Vim modes (normal/insert, Esc)
- [ ] Minigames: floating letters, password scream

## Conventions
- Computer minigames live in `minigames/computer/minigames/<name>/`: a scene whose root extends `Minigame`, a `MinigameConfig` subclass + default `.tres`, and one line in `minigame_registry.tres`. Minigames never decide when they start; the event manager calls `Computer.start_minigame(id, overrides)`
- Interactive props are wrapper scenes in `world/office/props/` (Node3D root + model + Interactable/script), made when the mechanic is built

## Suggestions awaiting approval
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

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

## Suggestions awaiting approval
- Add a `Furniture` group node in `office.tscn` and move `Office_Desk_1` into it
- Plugin: Godot Asset Placer (free, open source): a dock to browse and place assets with snapping
- Plugin: godot-snappy (MIT): hold V to snap to another object's vertices
- GridMap MeshLibrary for wall, floor and door pieces (paint the 2 m grid)
- Pre-made wrapper scenes for future interactable props in `world/office/props/`
- Trimesh collision for floor and wall imports
- Lower the music while the narrator speaks
- Keep audio playing while the game is paused (for the pause menu)
- Positional 3D sound effects (`play_sfx_3d`)
- Different footstep sounds per floor surface
- Subtitle-only narrator cues (no audio yet)
- Subtitles on/off setting
- A size property on narrator triggers that can be edited in the editor
- Chained cues (one line starts the next)
- Remember player position/rotation when returning from a minigame (currently respawns at start)
- Hide subtitles on scene change
- Build the interact prompt from the current key binding (for the WASD→ESDF remap gag)
- Outline/highlight on the targeted object
- Alternate hands per click
- Interactable enabled / one-shot flag
- Fade transition between scenes

# Office Metacommentary Surrealist Interactive Game

Working copy of the team's HackMD plan. Agents read this before every task and may update it (e.g. tick off tasks, record decisions).

# General description

This will be a simple interactive fiction game, strongly inspired by the Stanley Parable.
You control a regular white-collar worker at a generic sterile inhospitable office, working overtime (unpaid of course).
The main gameplay will be provided by minigames that occur across a mostly linear story, with each one designed to throw off the player's expectations.
The story will be driven by an omniscient disembodied narrator who will be providing scathing commentary over each beat. Fourth wall breaks will be quite frequent, and meta humour will be a staple. Along with the provided themes, the game would also like to explore the absurdities of seemingly mundane life (at a somewhat shallow level, this is a short game jam after all).

We imagine the graphics to be mostly 3d, there may be some 2d assets to further add to the absurdity of the game.

The audio narration/voice acting will be done in house by the team members.

## Some mechanics we will include (read the theme first to understand a bit more about what we imagine the gameplay to be)
- there is a button pressing which does nothing at all except just dialogues
- lights are the main antagonist/hurdle towards the player completing their task of writing on the document. the gameplay loop is the light keeps going out and the player must fix it to continue working on their comic sans project. each instance of fixing it has its own
    - initial path is simple and you turn a switch
    - second path you go the same way there's no switch, narrator will make fun of you
    - there's a bunch of extra doors
    - you need to light a candle instead
    - you pick up a pair of binoculars and twist it only to discover it is a kaleidoscope and the world twisted instead of zooming in
    - etc.
- in the end, the final mechanic/interaction will be looking for your glasses. inspired by everything everywhere all at once: you try on different glasses and see the world in different ways. after the correct pair of glasses you see the real world.

# Themes

The entire game is expected to be comical, bordering on bizarre. The main task will be writing scripts for comics. The Comic family of fonts (including the classic Comic Sans) will be used almost everywhere. The initial task of the protagonist is to write a document and they discover that they can only use Comic Sans fonts on their computer. Frequent puns about comics will be dropped in narration (this will be true for all three themes, hopefully).

Light will be the primary antagonist of the game. A lot of the actions of the protagonist will be in response to losing out on some light that is essential to your work. The humour would make the game light-hearted, despite not being for the light-hearted.

The plot will twist, and minigames through the game will involve things twisting: the world will twist through kaleidoscope, letters twist on the screen, your paths twist as you walk on them. Puns (twisting the meaning of words) of course will be aplenty.

# Appendix: Team details

- Vishesh Saraswat (@vishesh)
- Druhan Shah (@druhanrshah)
- Nandini Chakaravarthy (@chakaravarthy51234)
- Kimaya Arora (@kimaya.arora)
- Arnav Gupta (@wintersolstice)

# Other ideas

- sleep money reduce
- side monitor with bee movie and subway surfers
- no budget for eating animation
- very good button that keeps saying why
- binoculars to kaleidoscope
- yellow brick road 2nd time
- "we havent developed this part of the game"
- character design but it doesnt matter
- weeping things from dr who
- imp/gnome messing with lights
- at least one of them is lying, nah both of us are
- glasses to real world
- restart power to exit vim
- only fonts available are comic family
- comic book gimmick at the end
- rewind / loop
- make them say password out loud 5 times and then just allow them to type
- take inspiration from the password game too
- keep changing the person's desk position
- in between if you try picking up anything your hand goes through it
- you have to keep going back to your desk to pick up things in order to open a door (key, torch etc.)
- genie's lamp as a powerup/tool and the genie twists your words and doesn't really ever do anything helpful
- random mannequins around the place, they have comicy faces / appearance changes every time you look at it

# Script joke notes (from map building)
- Server room has no real mainframes: they're giant scaled-up PC cases and stacks of PCs, plus one beige "legacy mainframe". Narrator should joke about it (budget cuts / "we couldn't afford servers").
- Weird paintings (incl. the realistic portrait `Painting_Small2`) are kept on purpose; narrator can comment on them.
- Room C2 is upside down: all its furniture is on the ceiling.
- Room B1 has its ceiling lights mounted on the walls instead (sideways room, with the sideways painting).
- TODO script: narrator jab(s) when the player keeps pushing office chairs around (system triggers a cue after a while; needs actual lines + recordings).
- TODO script: real narrator mocking lines for pressing X on locked objects (e.g. the genie lamp before it's unlocked; doors that won't open yet). Placeholders now: subtitle-only `narration/locked_1..3.tres` (generic, picked at random); per object, set `Interactable.locked_cues` to its own lines.

# Not tasks but ideas/decisions
- Make the graphics hand drawn-y / comicy for all the mini games
- the main person had dreams of being a stand up comic / works as a typesetter for comic books

# Tasks/things to be done

- [ ] character design screen where you can change the appearance of some character -- change hair/clothes etc. after you are done the character is destroyed and you are told you don't have control here
    - [ ] if you don't spend time here the narrator says something snarky anyway
- [ ] a button in the main menu that does nothing when you press it except the narrator get annoyed
- [ ] main world that you walk around in
    - [ ] the controls change mid game, wasd shifts to one right and becomes esdf
    - [ ] mirror maze you keep crashing or mirror maze where your reflection keeps getting warped etc.
    - [ ] genie lamp is somewhere. not a mini game but funny interaction -- dialogue tree
        - [ ] genie lamp can only be used later
- [ ] computer itself can have some mini games including. you start seeing the computer screen
    - [ ] letters/words keep floating around and you need to drag them back to place
    - [ ] you need to replace words/phrases with more corporate speech
    - [ ] have captcha in the game
    - [ ] ad button small X you need to press
    - [ ] password scream to get it to log in then it shows text box instead
    - [ ] you have a button to go to sleep but your bank balance keeps dropping if you do that
- [ ] minigames/interaction "modes" you enter when you reach some locations
    - [ ] 1. get to switchboard and you have to connect wires like the among us task. twist screws to open switchboards
    - [ ] 2. you go back to the same place and discover the switchboard isn't there anymore. you look around see yellow bricks leading to a new switchboard. this one doesn't work like the previous one and connecting the same colors doesn't work. also the twisting is reversed(?)
    - [ ] 3. riddle from sphinx in front of the switchboard. you need to answer the riddles to access it. kbc type with the kbc sound, clock name ticking, impossible quiz type questions with puns.
    - [ ] another guy (garden gnome/imp) when you leave the room with the light switch then the light turns back off immediately as soon as you close the door, you turn back and when you reenter the garden gnome is wobbling -> take garden gnome out of the room. <heheheh>
    - [ ] password is on a sticky note far away. you use binoculars to see and it turns out to be a kaleidoscope

# Script beats

[Another HackMD](https://hackmd.io/join/note/6FeV83Bii3)

# Done so far (engineering log)

- 3D office room: VNB low-poly office pack imported (shared materials + collision), carpet floor, white walls, grid ceiling at 3.875 m, 9 cold-blue ceiling spot lights, SSAO instead of real-time shadows (Compatibility renderer), fog/glow.
- First-person player: CharacterBody3D, WASD + mouse look, head bob (`game/core/player/`).
- godot-ai MCP addon committed; its export plugin strips the `_mcp_game_helper` autoload automatically.
- Audio: buses Master → Music / SFX / Voice (`game/default_bus_layout.tres`). `Audio` autoload (`game/core/audio/`): `Audio.play_sfx(stream)`, `Audio.play_music(stream)` (music keeps playing across scene changes). Player footsteps play at the bottom of each head bob (`core/audio/footsteps.tres`, an AudioStreamRandomizer). Placeholder WAVs in `game/assets/audio/` (generated, see CREDITS.md).
- Narrator: `Narrator` autoload (`game/core/narrator/`). Cues are `NarratorCue` resources in `game/narration/<cue_id>.tres` (audio + subtitle + `once`); play with `Narrator.play(&"cue_id")`. A new line interrupts the current one. Drop `core/narrator/narrator_trigger.tscn` into a level and set `cue_id` to cue a line when the player walks in (example: `DeskNarratorTrigger` in office.tscn). Subtitles at bottom centre in Comic Neue Bold (OFL, `game/assets/fonts/`).
- Interaction: `Interactable` (Area3D class, `game/core/interaction/interactable.gd`) on physics layer 2 "interactable". The player's `InteractRay` (2 m, from the camera) shows its `prompt` under the crosshair; **X** (`interact` action) plays the Interactable's `sound` and changes to `target_scene` (or just emits `interacted`). Example: `world/office/props/computer.tscn` on the desk → `minigames/placeholder/placeholder_minigame.tscn` (Esc/X/button returns; mouse visible there, captured again in the office). NarratorTrigger now has `collision_layer = 0` so it doesn't block the ray.
- HUD (`core/player/hud.tscn`): white dot crosshair with dark outline (grows while aiming at an interactable) + prompt label.
- Hands (`core/player/hands.tscn`, class `PlayerHands`): rigged first-person arms from "PSX First Person Arms" (Drillimpact, CC0; `assets/models/arms/arms_rig.glb`, `relax` set to loop in its import settings). The rig is turned 180° (glTF faces +Z) with its `camera` bone on the camera and scaled 0.6 around it (looks the same, but even the grab's fingertips stay within ~0.29 m, inside the 0.3 m capsule, so no wall clipping). `ArmsMesh` casts no shadow (editable-children override). Idles on `relax`; `touch(point)` plays the visible part of `grab_R` (0.15–0.5 s, `play_section`, 0.12 s blend) and blends back to `relax`, ignored while grabbing (now through an AnimationTree, see Arms polish). Left click (`touch`) and **X** on an interactable both grab; left click also plays the player's `touch_sound` if the ray hits something.
- `GameState` autoload (`game/core/game_state.gd`): survives scene changes. The player saves its pose (body transform + head pitch) per level scene in `_exit_tree()` and restores it in `_ready()`, so returning from a minigame puts you back where you were.
- Narrator: `Narrator.stop()` cuts the current line. On `SceneTree.scene_changed` the line and its subtitle stop, unless the new scene cued it from its own `_ready()`.
- Music ducking: `Audio` lowers the music player by `duck_db` (-12 dB, 0.3 s tween) on `Narrator.line_started` and restores it on `line_finished`. It changes the player's volume, not the Music bus, so a future volume setting can own the bus.
- Interact prompt: `Interactable.verb` (e.g. "use the computer"); the HUD shows "Press <key> to <verb>" with the key read from the `interact` action in the InputMap (`PlayerHud.key_name()`), so remapping updates prompts.
- Office scene: furniture lives under a `Furniture` Node3D group (`Office_Desk_1`, `Computer`), kept at the origin so child positions are world positions.
- Editor plugins (editor-only, no autoloads): Godot Asset Placer 1.6.0 (`addons/asset_placer`, MIT) for click-placing models, and godot-snappy (`addons/snappy`, MIT, main @ 4fdaaa3) for V-drag vertex snapping. Usage in `docs/tutorials/placing-assets.md`. Asset Placer thumbnails/palettes stay in `user://` (per person); its asset library is shared (see below).
- Pausing: `Audio` and `Narrator` autoload roots use `process_mode = Always`, so music, SFX, narrator lines, subtitles and ducking keep running while `get_tree().paused` is true (for a pause menu).
- Real SFX from Chequered Ink's 400 Sounds Pack (free incl. commercial, credit optional; `game/assets/audio/sfx/400_sounds_pack/`, unaltered): 4 carpet footsteps in `footsteps.tres` (played at `Player.footstep_volume_db` -10 dB, ±1.5 dB / pitch 1.08 randomisation), `click_double_on.wav` as the default `Interactable.sound` (`sound_volume_db` -4 dB), `wood_small_hollow.wav` as `Player.touch_sound` (`touch_volume_db` -6 dB). Generated placeholder SFX removed (placeholder music/narrator kept). `game/CREDITS.md` lists every third-party resource (shipped vs editor-only).
- Export: `game/export_presets.cfg` has one **macOS** preset (output `game/export/macos/`, gitignored; no signing/notarization secrets, ad-hoc signing). Its `exclude_filter` drops `addons/asset_placer/*`, `addons/snappy/*`, `addons/godot_ai/*` and the Asset Placer library JSON from builds (checked with a headless `--export-pack`: no addon files, `_mcp_game_helper` stripped). Shared Asset Placer library: `asset_placer/general/asset_library_path = res://assets/asset_placer_library.json` in project.godot, pre-filled with `res://assets/vnb_office/models` (170 models, ids = the models' UIDs).
- Subtitle-only narrator cues: a `NarratorCue` with no `stream` shows its subtitle for `max(2 s, characters / 15 per s)` (a bit under Netflix's 17 chars/s adult limit), via the Narrator's `ReadTimer`; signals, ducking, `once`, interrupts and scene-change stop behave as for voiced lines. Example: `narration/placeholder_minigame.tres`, cued from the placeholder minigame's `_ready()`.
- `Interactable.enabled` (default true): when false the player's ray ignores it (no prompt, no crosshair growth, X does nothing). Set it from code to unlock things later. It resets when the scene reloads, so persistent unlocks belong in `GameState`.
- Scene fades: `Transition` autoload (`game/core/transition/`, CanvasLayer 100, process mode Always). `Transition.change_scene(path)` fades to black (`fade_time` 0.3 s), changes scene, fades back in, swallows all input meanwhile and ignores repeat calls. Used by `Interactable` and the placeholder minigame. Narrator subtitles moved to CanvasLayer 101 so they stay readable over the fade.
- Global unlocks: `GameState.unlock(&"genie_lamp")` / `lock(id)` / `is_unlocked(id)`, signal `unlock_changed(id, unlocked)`; ids are snake_case names of the thing. Set `Interactable.unlock_id` in the Inspector and it stays unusable until that id is unlocked from any scene (checked live every frame, survives scene changes). Usable = `enabled` (local, resets on reload) and unlocked; the player asks `Interactable.is_usable()`. Not saved to disk yet.
- Office map phase 1 (structure, layout in `docs/map/README.md` + `layout_topdown.png`): 10 rooms of 12 × 16 m (Start + 3×3 grid A1…C3, C1 = server/generator room), 13 open doorways (`WallDoorway`, no leaves) between every pair of rooms sharing a wall, Start only into A2. `Floor`, `Walls` and a new `Ceiling` GridMap (library `Ceiling` item, replaces the `ceiling_tile.tscn` instances, now deleted) sit at the origin; shared walls are single pieces, assigned to cells by a matching so no cell needs two walls. Scene tree: `Rooms/<Room>` Node3Ds at each room centre with `Lights` (12 `CeilingLight`s, 4 m grid) and `Furniture` (room-local coordinates). Player desk + computer (now on the desk top, y 0.949) + `DeskNarratorTrigger` moved into `Rooms/Start`; player spawns facing the desk (west).
- Lights at scale: 120 spotlights. `CeilingLight` range 7 → 6 m and `Floor`/`Walls` octant size 8 → 2 (4 m chunks), so every chunk is lit by ≤ 9 lights (Compatibility limit `max_lights_per_object` = 16; a spot's cull box is range × sin(angle) wide). `rendering/limits/opengl/max_renderable_lights` 32 → 128 so lights seen through doorways don't pop. Uncapped FPS at 1152×648: 1000–1190 across the map (was 1067 with one room); up to ~360 draw calls.
- Pushable office chairs: `world/office/props/office_chair.tscn` (script `office_chair.gd`), a `RigidBody3D` (12 kg, X/Z rotation locked so it never tips, wheel friction 0.05, `linear_damp` 1.5 as rolling resistance: a walking-speed shove glides ~2.5 m and stops in ~1.5 s) with one 0.4 m cylinder collider and plain `MeshInstance3D`s (back + bottom + 5 wheels per the furnishing guide). The meshes are saved from the FBX imports to `assets/vnb_office/meshes/` (import option *Save to File*), because instancing the `.fbx` brings a StaticBody3D (and a VehicleWheel3D for the wheel) that must not sit inside a RigidBody. Pick the back with the `model` export (Task/blue, Armchair/black (default), Executive/high back; `@tool`, previews in the editor). Player pushes with the standard `get_slide_collision()` pattern (`Player._push_bodies`, horizontal force `push_force` 300 N, only while the body is slower than the player). Rolling loop `assets/audio/sfx/chair_roll_loop.wav` (Freesound, CC0, see audio CREDITS) on an `AudioStreamPlayer3D` (SFX bus): volume and pitch 0.8–1.2 follow speed, silent when still. 3 test chairs in `Rooms/Start/Furniture` (`PlayerChair` at the desk). For a chair that must not move (ceiling room, gags), set `freeze = true` on the instance.
- Arms polish: `Hands/Arms/AnimationTree` (BlendTree): `relax` → `push` (Blend2, right-arm bone filter, `push_R` 0.15–0.5 s ping-pong) → `grab_R` / `grab_L` (OneShots filtered to that arm's bones, 0.15–0.5 s of the clip, 0.12 s fades), so the other arm keeps its idle/push pose. `touch(point)` grabs with the left hand when the point is more than `left_grab_angle` (5°) left of the crosshair in camera space, else the right; ignored while either grab plays. X on an interactable now reaches toward the Interactable's origin (left click still uses the ray hit, i.e. always the right hand). `Player._push_bodies` calls `hands.push()` for every rigid body it bumps; the push pose fades in/out over `push_blend_time` 0.2 s and is held `push_hold` 0.3 s after the last bump. Sway: `Hands` rotates (around the camera, so arm-to-camera distance and the no-wall-clipping margin are unchanged) by the camera's turn rate × `sway_lag` 0.04 s, smoothed (`sway_speed` 12/s) and clamped to `max_sway_degrees` 4°; it reads the camera's rotation, not mouse events, so it's frame-rate and sensitivity independent.
- Furnishing 1/2 (`docs/map/furnishing_plan.md`, deviations listed there; screenshots in `docs/map/screenshots/`): prefabs in `world/office/props/sets/` — `ws_modern`/`ws_retro` (workstations, mug always at desk-local (0.55, 0.949, 0.05)), `desk_pair` (2 back-to-back desks + 2 pushable chairs), `file_cabinet` (cabinet + 3 closed drawers), `bookshelf_stocked`/`shelf_stocked` (Bookshelf / Shelf_Base with books and binders), `server_rack`/`server_rack_legacy` (StaticBody3D + BoxShape3D, the case mesh saved via the FBX import option *Save to File* to `assets/vnb_office/meshes/Computer_Case*.res` and scaled (3.2, 4.6, 2.6)), `pc_shelf_stack`, `wall_clock` (`@tool` `wall_clock.gd`: `hour`, `minute`, `minutes_per_second`, 0 = stopped, −1 = backwards). Painting variants `world/office/materials/painting_2/3/4.tres` (Paintings2–4 textures) go on the painting's surface 1 as a surface material override. Rooms Start, A2, A1, A3, B2, B1, B3 furnished under `Rooms/<Room>/Furniture` (Start: test chairs removed; clocks count back a minute per room from Start's 6:59). B1's ceiling lights are mounted on the walls (9 instead of 12, rot (−90, facing, 0) at y 2.6, SpotLight range 7.5 / angle 75° / energy 3 via editable children). Uncapped FPS (separate process, 1152×648, editor open): ~470 → ~430 in B2's west doorway, ~460 → ~400 in B2, ~420 → ~350 looking from Start into A2; draw calls roughly double (153 → 292, 274 → 664).
- Furnishing 2/2 (`docs/map/furnishing_plan.md` "As built (part 2)", screenshots `docs/map/screenshots/c1–c3*.png`): C1 server room (21 giant-PC racks + beige legacy mainframe with photo/sticky/"DO NOT TOUCH", PC stacks and wall, floor fans, CRT monitoring desk, "DAYS SINCE LAST BLACKOUT: 0" board, clock 6:54, `SwitchboardSpot` Marker3D on the east wall at the end of the aisle, area kept clear); all 12 C1 lights amber (editable-children overrides + new `world/office/materials/ceiling_light_panel_amber.tres`), and `CeilingLight6`/`9` flicker via `world/office/parts/light_flicker.gd` (steady, every 2–6 s a short burst of 2–5 partial dips; `enabled` = flicker on/off, `powered` = light on/off; pauses with the game). C2: everything on the ceiling (pinwheel with frozen chairs, lamps, counter + coffee machine, cabinets, lounge corner, plants), upside-down painting/whiteboard/TV, clock 6:55 running backwards; on the floor only an upright pushable chair and `CeilingLight7`, moved to the floor shining up. C3: four desk pairs twisted 0/15/30/45°, a meeting of five chairs around a plant with a projector, twisting paintings, sandwich on a keyboard, briefcase wall. Uncapped FPS in the C rooms 590–700; part-1 spots unchanged (B2 ~435, Start → A2 ~350).
- Interaction batch: a locked `Interactable` (`unlock_id` set, not unlocked yet) now shows its prompt and grows the crosshair like a usable one, but X plays a random cue from `locked_cues` (default the subtitle-only placeholders `narration/locked_1..3.tres`) instead of the sound/`interacted`/scene change (`is_locked()`; `enabled = false` still hides it completely). Highlight: the targeted Interactable sets the shared `core/interaction/highlight.tres` (unshaded additive shader: faint warm tint + fresnel rim, gentle pulse) as `material_overlay` on every MeshInstance3D under `highlight_root` (default `..`, the prop wrapper) and clears it when you look away; meshes' own materials are untouched, meshes that already have an overlay are skipped. No measurable FPS cost (~877 uncapped either way at the desk). Unlock ids live in `core/unlocks.gd` (`class_name Unlocks`, e.g. `GameState.unlock(Unlocks.GENIE_LAMP)`; `ALL` lists them); `unlock_id` is `@export_custom(PROPERTY_HINT_ENUM_SUGGESTION, Unlocks.ALL)`, a dropdown that still accepts typing, and an id not in the list logs a warning at runtime.

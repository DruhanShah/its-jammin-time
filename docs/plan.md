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
- Hands (`core/player/hands.tscn`): placeholder skin-coloured boxes under the camera, kept within the player's 0.3 m capsule so they don't clip walls. Left click (`touch` action) reaches the right hand toward the crosshair; plays the player's `touch_sound` if the ray hits something.
- `GameState` autoload (`game/core/game_state.gd`): survives scene changes. The player saves its pose (body transform + head pitch) per level scene in `_exit_tree()` and restores it in `_ready()`, so returning from a minigame puts you back where you were.
- Narrator: `Narrator.stop()` cuts the current line. On `SceneTree.scene_changed` the line and its subtitle stop, unless the new scene cued it from its own `_ready()`.
- Music ducking: `Audio` lowers the music player by `duck_db` (-12 dB, 0.3 s tween) on `Narrator.line_started` and restores it on `line_finished`. It changes the player's volume, not the Music bus, so a future volume setting can own the bus.
- Interact prompt: `Interactable.verb` (e.g. "use the computer"); the HUD shows "Press <key> to <verb>" with the key read from the `interact` action in the InputMap (`PlayerHud.key_name()`), so remapping updates prompts.
- Office scene: furniture lives under a `Furniture` Node3D group (`Office_Desk_1`, `Computer`), kept at the origin so child positions are world positions.
- Editor plugins (editor-only, no autoloads): Godot Asset Placer 1.6.0 (`addons/asset_placer`, MIT) for click-placing models, and godot-snappy (`addons/snappy`, MIT, main @ 4fdaaa3) for V-drag vertex snapping. Usage in `docs/tutorials/placing-assets.md`. Asset Placer thumbnails/palettes stay in `user://` (per person); its asset library is shared (see below).
- Pausing: `Audio` and `Narrator` autoload roots use `process_mode = Always`, so music, SFX, narrator lines, subtitles and ducking keep running while `get_tree().paused` is true (for a pause menu).
- Real SFX from Chequered Ink's 400 Sounds Pack (free incl. commercial, credit optional; `game/assets/audio/sfx/400_sounds_pack/`, unaltered): 4 carpet footsteps in `footsteps.tres` (played at `Player.footstep_volume_db` -10 dB, ±1.5 dB / pitch 1.08 randomisation), `click_double_on.wav` as the default `Interactable.sound` (`sound_volume_db` -4 dB), `wood_small_hollow.wav` as `Player.touch_sound` (`touch_volume_db` -6 dB). Generated placeholder SFX removed (placeholder music/narrator kept). `game/CREDITS.md` lists every third-party resource (shipped vs editor-only).
- Export: `game/export_presets.cfg` has one **macOS** preset (output `game/export/macos/`, gitignored; no signing/notarization secrets, ad-hoc signing). Its `exclude_filter` drops `addons/asset_placer/*`, `addons/snappy/*`, `addons/godot_ai/*` and the Asset Placer library JSON from builds (checked with a headless `--export-pack`: no addon files, `_mcp_game_helper` stripped). Shared Asset Placer library: `asset_placer/general/asset_library_path = res://assets/asset_placer_library.json` in project.godot, pre-filled with `res://assets/vnb_office/models` (170 models, ids = the models' UIDs).

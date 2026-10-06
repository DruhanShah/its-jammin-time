# Audio

## 400 Sounds Pack (sound effects)

- **Author:** Chequered Ink, https://ci.itch.io/
- **Source:** https://ci.itch.io/400-sounds-pack
- **License (verbatim from the itch.io page):** "You may use these game assets for ANY and ALL uses including commercial use, with or without giving credit, except that you may not sell or redistribute the unaltered assets as your own game assets."
- **AI disclosure:** The itch.io page states no generative AI was used.
- **Files used** (unaltered, original filenames, in `sfx/400_sounds_pack/`):
  - `foley_footstep_carpet_1.wav` … `foley_footstep_carpet_4.wav` (pack folder `Footsteps/`): player footsteps, via `core/audio/footsteps.tres`.
  - `click_double_on.wav` (pack folder `UI/`): default `Interactable` sound.
  - `wood_small_hollow.wav` (pack folder `Materials/`): player hand touching something.
  - `door_open.wav`, `door_close.wav` (pack folder `Environment/`): the openable door prop (`world/office/props/door.tscn`). Imported as mono (import option only; the files are unaltered).
  - `subtle_knock.wav` (pack folder `Other/`): office chair bumping into something (`world/office/props/office_chair.tscn`). Imported as mono.
  - `foley_creak_1.wav` (pack folder `Footsteps/`): occasional office chair caster creak while rolling (pitched up in the scene). Imported as mono.
  - Visit 1 font step + ad storm (`minigames/computer/minigames/font_picker/`, `ad_storm/`): `select_1.wav`, `pop_1.wav`, `pop_3.wav`, `pop_4.wav`, `toggle_off.wav` (pack folder `UI/`): font list hover, ad pop-up (random pick, `ad_spawn_sfx.tres`), ECO MODE accepted; `wobble.wav`, `punch.wav`, `jump_short.wav` (pack folder `Retro/`): nested ad opening, ad closed ("POW!"), the runner ad's X hopping away; `coins_gather_medium.wav` (pack folder `Items/`): Comic font accepted ("KA-CHING!"); `elastic_twang.wav`, `record_scratch.wav` (pack folder `Other/`): decoy click ("BOING!"), the countdown ad lying; `brass_level_start.wav` (pack folder `Musical Effects/`): the ECO MODE ad sliding in.
  - **Modified:** `keyboard_key_1.wav` … `keyboard_key_4.wav`: four single keystrokes cut (85 ms each, 5 ms fades, normalised to −4.4 dB peak) from the pack's `Other/keyboard_typing.wav` at 0.454, 0.984, 1.964 and 2.114 s; the ad storm's scripted typing (`ad_storm/typing_sfx.tres`, random pick + pitch).

Credit line for the game's credits screen (optional per the license):

> Sound effects from 400 Sounds Pack by Chequered Ink, https://ci.itch.io/

## Rolling office chair (sound effect)

- **Title:** "rolling_office_chair.WAV"
- **Author:** alpanaytekin, https://freesound.org/people/alpanaytekin/
- **Source:** https://freesound.org/people/alpanaytekin/sounds/213086/ (uploaded 2014-01-05; description: "rolling office chair. suitable for looping.")
- **License:** Creative Commons 0 (CC0 1.0, public domain dedication), https://creativecommons.org/publicdomain/zero/1.0/
- **File:** `sfx/chair_roll_loop.wav`, **modified**: cut from the Freesound HQ preview (source 9.20–12.20 s, 3.0 s) with a 0.25 s crossfade so it loops seamlessly. Imported as mono with forward looping. Used by `world/office/props/office_chair.tscn` while a chair rolls.

Credit line (optional under CC0):

> Rolling chair sound: "rolling_office_chair.WAV" by alpanaytekin (Freesound), CC0

## Freesound clips for the switch games (`sfx/freesound/`)

All CC0 1.0 (public domain), https://creativecommons.org/publicdomain/zero/1.0/. **Modified:** each file is a short cut from the Freesound HQ preview (times below), with short fades and normalised peak; one-shots, no loop.

| File | Source sound | Author | Cut | Used for |
|---|---|---|---|---|
| `screw_click_1_toman.wav`, `screw_click_2_toman.wav` | "Screwdriver 1", https://freesound.org/people/16GPanskaToman_Kristian/sounds/496286/ | 16GPanskaToman_Kristian | 4.56–4.86 s and 13.42–13.72 s, mono | one per twist step in the screwdriver game (random pick) |
| `screw_drop_bolt_zemba.wav` | "Bolts into Iron Pipe Flange", https://freesound.org/people/zembacraftworks/sounds/428340/ | zembacraftworks | 0.24–1.20 s | an unscrewed screw dropping |
| `panel_clatter_vent_me_studios.wav` | (untitled) vent cover taken off, https://freesound.org/people/ME_Studios_Official/sounds/649765/ | ME_Studios_Official | 1.05–2.40 s, mono | the switchboard cover falling off |
| `wire_plug_in_preyk.wav` | "plug getting connected to wall socket", https://freesound.org/people/preyk/sounds/525017/ | preyk | 0–0.38 s | a wire plugged in straight (wires game) |
| `spark_zap_grinnell.wav` | "Electric zap.wav", https://freesound.org/people/michael_grinnell/sounds/512471/ | michael_grinnell | 0–0.22 s | big zap: a wire plugged into its matching colour (wires game) |
| `spark_klein.wav` | "Spark", https://freesound.org/people/elliott.klein/sounds/189630/ | elliott.klein | 0–0.17 s | small zap: crossed wires (wires game) |
| `breaker_clunk_on_kyles.wav` | "switch big breaker metal click on, off.flac", https://freesound.org/people/kyles/sounds/451933/ | kyles | 0.10–1.40 s, mono | the wires game's lever pulled |
| `power_on_neon_hum_kinoton.wav` | "Neon Lamp, Switch On, Hum", https://freesound.org/people/Kinoton/sounds/351430/ | Kinoton | 0.2–6.0 s (fades out) | lights coming back on after the wires game |

Credit lines (optional under CC0):

> Screwdriver sounds by 16GPanskaToman_Kristian, bolt drop by zembacraftworks, panel clatter by ME_Studios_Official (Freesound), CC0
> Wire plug by preyk, zaps by michael_grinnell and elliott.klein, breaker by kyles, neon hum by Kinoton (Freesound), CC0

## Gargoyle quiz ("WHO WANTS TO BE A LUMEN-AIRE?", `world/office/props/gargoyle_gate/`)

Freesound, all CC0 1.0 (public domain), https://creativecommons.org/publicdomain/zero/1.0/, in `sfx/freesound/`. **Modified:** each file is a cut from the Freesound HQ preview (times below) with short fades and normalised level; loops are imported with Loop Mode = Forward. None of it is from the TV show.

| File | Source sound | Author | Cut | Used for |
|---|---|---|---|---|
| `quiz_think_loop_portwain.wav` | "quiz game music loop BPM 90.wav", https://freesound.org/people/portwain/sounds/220060/ | portwain | 0–16.0 s, loop | music while a question is up |
| `quiz_heartbeat_loop_loudernoises.wav` | "heartbeat-60bpm.wav", https://freesound.org/people/loudernoises/sounds/332821/ | loudernoises | 0–4.0 s, loop | suspense after "final answer" |
| `quiz_lights_slam_grubzyy.wav` | "S_Spotlight_On.wav", https://freesound.org/people/Grubzyy/sounds/422736/ | Grubzyy | 1.40–4.40 s | the lights slamming into the show look, each spotlight |
| `quiz_intro_hit_horns_devern.wav` | "Cinematic Hit With Horns.wav", https://freesound.org/people/DeVern/sounds/427803/ | DeVern | 0–4.37 s | the show starting |
| `quiz_final_answer_boom_harrisonlace.wav` | "DSGNStngr_basic trailer boom impact", https://freesound.org/people/harrisonlace/sounds/816376/ | harrisonlace | 0–3.0 s | answer locked in |
| `quiz_correct_bwg2020.wav` | "Correct.wav", https://freesound.org/people/bwg2020/sounds/456161/ | bwg2020 | 0–1.41 s | right answer |
| `quiz_correct_harp_oggraphics.wav` | "Good answer harp glissando.wav", https://freesound.org/people/oggraphics/sounds/610703/ | oggraphics | 0–2.5 s | quiz passed |
| `quiz_wrong_buzzer_kevinvg207.wav` | (see "Wrong buzzer" below) | KevinVG207 | | wrong answer |
| `stone_grind_step_aside_postproddog.wav` | "Heavy stone door opens 2", https://freesound.org/people/PostProdDog/sounds/578491/ | PostProdDog | 1.0–4.2 s, 0.7 s fade-out | the gargoyles sliding aside |
| `rumble_step_aside_unfa.wav` | "Rumble · fade in 10s", https://freesound.org/people/unfa/sounds/258341/ | unfa | 7.0–9.5 s, 1.5 s fade-out | rumble under the slide |

400 Sounds Pack (Chequered Ink, licence above), unaltered, in `sfx/400_sounds_pack/`: `clock_ticking.wav` (pack folder `Environment/`, imported with Loop Mode = Forward): ticking under a question; `clock_tick_only.wav` (`Environment/`): each time the "timer" jumps to a new nonsense value; `stone_push_short.wav` (`Materials/`): the gargoyles' per-word "voice" blips (random pitch); `pop_2.wav` (already listed): a lifeline used.

Credit line (optional under CC0):

> Quiz sounds by portwain, loudernoises, Grubzyy, DeVern, harrisonlace, bwg2020, oggraphics, KevinVG207, PostProdDog and unfa (Freesound), CC0

## Kenney Interface Sounds 1.0 (`sfx/kenney/`)

- **Author:** Kenney, https://www.kenney.nl/
- **Source:** https://kenney.nl/assets/interface-sounds
- **License:** Creative Commons Zero (CC0 1.0), https://creativecommons.org/publicdomain/zero/1.0/ ("free to use in personal, educational and commercial projects", credit not mandatory)
- **Files used** (unaltered): `tick_001.ogg`: the countdown ad's honest ticks.

## Wrong buzzer (`sfx/freesound/quiz_wrong_buzzer_kevinvg207.wav`)

- "Wrong Buzzer" by KevinVG207, https://freesound.org/people/KevinVG207/sounds/331912/ (2015-12-28), CC0 1.0. **Modified:** cut 0–0.49 s from the Freesound HQ preview, short fades, normalised to −12 dB peak. Used when a non-Comic font is picked in the visit-1 font step.

## Computer UI sounds

- 400 Sounds Pack (Chequered Ink, licence above), unaltered, in `sfx/400_sounds_pack/`: `pop_2.wav` (pack folder `UI/`): an `AppWindow` popping open; `whoosh_1.wav` (pack folder `Other/`): an `AppWindow` closing ("POOF!"); `power_down.wav` (pack folder `Retro/`): the CRT-off at the end of `Computer.blackout()`.
- `sfx/freesound/spark_crackle_nachtmahr.wav`: "Electricity Sound" by NachtmahrTV, https://freesound.org/people/NachtmahrTV/sounds/556717/, CC0 1.0. **Modified:** cut 0.10–1.15 s from the Freesound HQ preview, short fades, normalised to −2 dB peak. Used for the screen flicker in `Computer.blackout()`.

Credit line (optional under CC0):

> Electricity crackle by NachtmahrTV (Freesound), CC0

## Placeholders (ours)

Generated procedurally by a small Python script (sine tones and filtered noise), made for this project. No third-party or AI-generated audio. Replace them with real recordings when ready.

- `music/placeholder_loop.wav`: 8 s quiet sine-chord loop (C, Am, F, G).
- `narrator/placeholder_desk_intro.wav`: ~3 s of speech-like beeps for the example narrator cue.

# Audio

## 400 Sounds Pack (sound effects)

- **Author:** Chequered Ink, https://ci.itch.io/
- **Source:** https://ci.itch.io/400-sounds-pack
- **License (verbatim from the itch.io page):** "You may use these game assets for ANY and ALL uses including commercial use, with or without giving credit, except that you may not sell or redistribute the unaltered assets as your own game assets."
- **AI disclosure:** The itch.io page states no generative AI was used.
- **Files used** (unaltered, original filenames, in `sfx/400_sounds_pack/`):
  - `foley_footstep_carpet_1.wav` … `foley_footstep_carpet_4.wav` (pack folder `Footsteps/`): player footsteps, via `core/audio/footsteps.tres`.
  - `toggle_on.wav` (pack folder `UI/`): default `Interactable` sound (a single soft click; replaced `click_double_on.wav`).
  - `click_double_on.wav` (pack folder `UI/`): switch flips and computer-minigame clicks.
  - `wood_small_hollow.wav` (pack folder `Materials/`): player hand touching something.
  - `door_open.wav`, `door_close.wav` (pack folder `Environment/`): the openable door prop (`world/office/props/door.tscn`). Imported as mono (import option only; the files are unaltered).
  - `subtle_knock.wav` (pack folder `Other/`): office chair bumping into something (`world/office/props/office_chair.tscn`). Imported as mono.
  - `foley_creak_1.wav` (pack folder `Footsteps/`): occasional office chair caster creak while rolling (pitched up in the scene). Imported as mono.
  - Visit 1 font step + ad storm (`minigames/computer/minigames/font_picker/`, `ad_storm/`): `select_1.wav`, `pop_1.wav`, `pop_3.wav`, `pop_4.wav`, `toggle_off.wav` (pack folder `UI/`): font list hover, ad pop-up (random pick, `ad_spawn_sfx.tres`), ECO MODE accepted; `wobble.wav`, `punch.wav`, `jump_short.wav` (pack folder `Retro/`): nested ad opening, ad closed ("POW!"), the runner ad's X hopping away; `coins_gather_medium.wav` (pack folder `Items/`): Comic font accepted ("KA-CHING!"); `elastic_twang.wav`, `record_scratch.wav` (pack folder `Other/`): decoy click ("BOING!"), the countdown ad lying; `brass_level_start.wav` (pack folder `Musical Effects/`): the ECO MODE ad sliding in.
  - Visit 3 boss emails (`minigames/computer/minigames/memo_mail/`): `8_bit_chime_positive.wav`, `8_bit_negative_quick.wav` (pack folder `Musical Effects/`): the boss's mood going up / down a band; `brass_positive_long.wav`, `grand_piano_chime_quick.wav` (pack folder `Musical Effects/`): promoted / the honest reply; `whoosh_2.wav` (pack folder `Other/`): reply sent; `synth_warning.wav` (pack folder `UI/`): Reply All pressing itself. Also reuses `click_double_on.wav` (word picked) and `pop_3.wav` (reply-all toasts).
  - Candle switch game (`minigames/switch/candle/`): `light_match.wav`, `slide_and_click.wav` (pack folder `Other/`): striking the match (the fizzles play only its first scratch), the wick planted in the candle; `fire_lighting.wav` (pack folder `Environment/`): the candle catching.
  - Antivirus download (visit 2, `minigames/computer/minigames/antivirus_download/`): `slide_and_click.wav` (pack folder `Other/`): the dial turning into a crank; `synth_process_complete.wav` (pack folder `UI/`): the download reaching 100 %.
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

All CC0 1.0 (public domain), https://creativecommons.org/publicdomain/zero/1.0/. **Modified:** each file is a short cut from the Freesound HQ preview (times below), with short fades and normalised peak; one-shots unless marked as a loop.

| File | Source sound | Author | Cut | Used for |
|---|---|---|---|---|
| `screw_click_1_toman.wav`, `screw_click_2_toman.wav` | "Screwdriver 1", https://freesound.org/people/16GPanskaToman_Kristian/sounds/496286/ | 16GPanskaToman_Kristian | 4.56–4.86 s and 13.42–13.72 s, mono | one per twist step in the screwdriver game (random pick) |
| `screw_drop_bolt_zemba.wav` | "Bolts into Iron Pipe Flange", https://freesound.org/people/zembacraftworks/sounds/428340/ | zembacraftworks | 0.24–1.20 s | an unscrewed screw dropping |
| `panel_clatter_vent_me_studios.wav` | (untitled) vent cover taken off, https://freesound.org/people/ME_Studios_Official/sounds/649765/ | ME_Studios_Official | 1.05–2.40 s, mono | the switchboard cover falling off |
| `wire_plug_in_preyk.wav` | "plug getting connected to wall socket", https://freesound.org/people/preyk/sounds/525017/ | preyk | 0–0.38 s | a wire plugged in straight (wires game) |
| `spark_zap_grinnell.wav` | "Electric zap.wav", https://freesound.org/people/michael_grinnell/sounds/512471/ | michael_grinnell | 0–0.22 s | big zap: a wire plugged into its matching colour (wires game); the candle flame arcing between the terminals (candle game) |
| `spark_klein.wav` | "Spark", https://freesound.org/people/elliott.klein/sounds/189630/ | elliott.klein | 0–0.17 s | small zap: crossed wires (wires game) |
| `breaker_clunk_on_kyles.wav` | "switch big breaker metal click on, off.flac", https://freesound.org/people/kyles/sounds/451933/ | kyles | 0.10–1.40 s, mono | the wires game's lever pulled; the candle game's lever flipping itself up |
| `power_on_neon_hum_kinoton.wav` | "Neon Lamp, Switch On, Hum", https://freesound.org/people/Kinoton/sounds/351430/ | Kinoton | 0.2–6.0 s (fades out) | lights coming back on after the wires, valve and candle games |
| `valve_squeak_1_joedeshon.wav`, `valve_squeak_2_joedeshon.wav`, `valve_squeak_3_joedeshon.wav` | "squeak_01.wav", https://freesound.org/people/joedeshon/sounds/339184/ | joedeshon | 0.30–1.20, 2.10–3.00 and 3.85–4.90 s | the valve's hand wheel squeaking (random pick) |
| `valve_turn_rusty_loop_noxsound.wav` | "Foley_Mechanism_Wheel_Moderate_Rusty_Loop_Mono.wav", https://freesound.org/people/Nox_Sound/sounds/559470/ | Nox_Sound | 8.0 s from 0.3 s, crossfaded into a **loop** (imported with Loop Mode Forward) | while the valve's wheel turns |
| `pipe_clunk_brittmosel.wav` | "Hitting a Pipe with a Hammer", https://freesound.org/people/brittmosel/sounds/530216/ | brittmosel | 16.64–17.80 s | the valve's reverse-thread gag |
| `pipe_flow_loop_rutgermuller.wav` | "Pressure Meter Pipe Noises 1.aif", https://freesound.org/people/RutgerMuller/sounds/104087/ | RutgerMuller | 8.0 s from 12.0 s, crossfaded into a **loop** (imported with Loop Mode Forward) | electricity flowing through the valve's pipes |
| `electric_surge_fkurz.wav` | "high-voltage.wav", https://freesound.org/people/fkurz/sounds/136614/ | fkurz | 0–6.9 s (the game fades it out at 2.5 s) | the valve fully open |
| `flame_whoosh_lookimadeathing.wav` | "Basic Fire whoosh", https://freesound.org/people/LookIMadeAThing/sounds/260554/ | LookIMadeAThing | 0–2.6 s | the candle catching (candle game) |
| `flame_crackle_loop_soundofsong.wav` | "fire crackling loop.wav", https://freesound.org/people/soundofsong/sounds/650574/ | soundofsong | 0–4.6 s with a 0.4 s crossfade into a seamless loop; imported with forward looping | the burning candle (candle game) |
| `wick_twist_1_noxsound.wav`, `wick_twist_2_noxsound.wav` | "Foley_Leather_Stress_Mono.wav", https://freesound.org/people/Nox_Sound/sounds/559079/ | Nox_Sound | 0.70–1.10 s and 4.35–4.70 s, mono, 15 ms / 80 ms fades | one per twist step while twisting the wick (candle game, random pick + pitch) |
| `crank_ratchet_1_xxqmanxx.wav`, `crank_ratchet_2_xxqmanxx.wav`, `crank_ratchet_3_xxqmanxx.wav` | "Socket Wrench", https://freesound.org/people/xxqmanxx/sounds/147018/ | xxqmanxx | one ratchet burst each (about 1.17–1.40 s, 2.27–2.46 s and 2.73–2.97 s of the original), mono, 4 ms / 30 ms fades, not normalised | one per key step while cranking the antivirus download (`antivirus_download/crank_ratchet.tres`, random pick + pitch) |

Credit lines (optional under CC0):

> Screwdriver sounds by 16GPanskaToman_Kristian, bolt drop by zembacraftworks, panel clatter by ME_Studios_Official (Freesound), CC0
> Crank ratchet by xxqmanxx (Freesound), CC0
> Wire plug by preyk, zaps by michael_grinnell and elliott.klein, breaker by kyles, neon hum by Kinoton (Freesound), CC0
> Valve squeaks by joedeshon, rusty wheel by Nox_Sound, pipe clunk by brittmosel, pipe noises by RutgerMuller, high voltage by fkurz (Freesound), CC0
> Fire whoosh by LookIMadeAThing, fire crackle by soundofsong, wick creaks by Nox_Sound (Freesound), CC0

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

400 Sounds Pack (Chequered Ink, licence above), unaltered, in `sfx/400_sounds_pack/`: `clock_ticking.wav` (pack folder `Environment/`, imported with Loop Mode = Forward): ticking under a question; `clock_tick_only.wav` (`Environment/`): each time the "timer" jumps to a new nonsense value; `stone_push_short.wav` (`Materials/`): no longer used (was the gargoyles' per-word blips); the gargoyles' babble (`speech_bubble.gd`) reuses `pop_1.wav`, `pop_3.wav`, `pop_4.wav` (already listed) plus `gravel_tick.wav`, the first 70 ms (mono, faded out) of `digital_footstep_gravel_2.wav` (pack folder `Footsteps/digital/`), cut for this game; `pop_2.wav` (already listed): a lifeline used.

Credit line (optional under CC0):

> Quiz sounds by portwain, loudernoises, Grubzyy, DeVern, harrisonlace, bwg2020, oggraphics, KevinVG207, PostProdDog and unfa (Freesound), CC0

## Kenney Interface Sounds 1.0 (`sfx/kenney/`)

- **Author:** Kenney, https://www.kenney.nl/
- **Source:** https://kenney.nl/assets/interface-sounds
- **License:** Creative Commons Zero (CC0 1.0), https://creativecommons.org/publicdomain/zero/1.0/ ("free to use in personal, educational and commercial projects", credit not mandatory)
- **Files used** (unaltered): `tick_001.ogg`: the countdown ad's honest ticks; `bong_001.ogg`: a new email arriving in MemoMail (visit 3).

## Wrong buzzer (`sfx/freesound/quiz_wrong_buzzer_kevinvg207.wav`)

- "Wrong Buzzer" by KevinVG207, https://freesound.org/people/KevinVG207/sounds/331912/ (2015-12-28), CC0 1.0. **Modified:** cut 0–0.49 s from the Freesound HQ preview, short fades, normalised to −12 dB peak. Used when a non-Comic font is picked in the visit-1 font step.

## Computer UI sounds

- 400 Sounds Pack (Chequered Ink, licence above), unaltered, in `sfx/400_sounds_pack/`: `pop_2.wav` (pack folder `UI/`): an `AppWindow` popping open; `whoosh_1.wav` (pack folder `Other/`): an `AppWindow` closing ("POOF!"); `power_down.wav` (pack folder `Retro/`): the CRT-off at the end of `Computer.blackout()`.
- 400 Sounds Pack (Chequered Ink, licence above), unaltered, in `sfx/400_sounds_pack/`: `slide_and_click.wav` (the kaleidoscope clicking into place, the keypad accepting the password) and `brass_positive_long.wav` (password revealed / access granted).
- `sfx/freesound/spark_crackle_nachtmahr.wav`: "Electricity Sound" by NachtmahrTV, https://freesound.org/people/NachtmahrTV/sounds/556717/, CC0 1.0. **Modified:** cut 0.10–1.15 s from the Freesound HQ preview, short fades, normalised to −2 dB peak. Used for the screen flicker in `Computer.blackout()`.

Credit line (optional under CC0):

> Electricity crackle by NachtmahrTV (Freesound), CC0

## Music (`music/`)

### "Piece for Disaffected Piano Two" (in-game background music)

- **Title:** "Piece for Disaffected Piano Two"
- **Author:** Kevin MacLeod, https://incompetech.com/
- **Source:** https://incompetech.com/music/royalty-free/mp3-royaltyfree/Piece%20for%20Disaffected%20Piano%20Two.mp3 (official incompetech download; ISRC USUAN1100458; also https://incompetech.filmmusic.io/song/4215-piece-for-disaffected-piano-two/). The team picked it from the YouTube upload https://www.youtube.com/watch?v=ZdfqsO0bLBA ("Kevin MacLeod Archive" channel); the audio was NOT taken from YouTube, only from incompetech.com.
- **License:** Creative Commons Attribution 4.0 (CC BY 4.0), https://creativecommons.org/licenses/by/4.0/ (attribution required).
- **File:** `music/piece_for_disaffected_piano_two.ogg`, **modified**: converted from the 320 kbps MP3 to Ogg Vorbis (q4), leading silence (0.95 s) and trailing silence trimmed (cut at 324.2 s, 0.5 s fade-out). Imported with Loop on. Played by the `Audio` autoload (`GAME_MUSIC`) from the start of the game proper (after the intro) for the rest of the game.

Required credit line (Kevin MacLeod's format):

> "Piece for Disaffected Piano Two" Kevin MacLeod (incompetech.com)
> Licensed under Creative Commons: By Attribution 4.0 License
> http://creativecommons.org/licenses/by/4.0/

### "Cheerful Comedy Funny Quirky Background" (start menu + character select)

- **Title:** "Cheerful Comedy Funny Quirky Background"
- **Author:** alex-morgan (Pixabay user; profile linked from the track page)
- **Source:** https://pixabay.com/music/cartoons-cheerful-comedy-funny-quirky-background-587373/ (downloaded from the page's own Pixabay CDN file, `alex-morgan-cheerful-comedy-funny-quirky-background-587373.mp3`, 0:25)
- **License:** Pixabay Content License, https://pixabay.com/service/license-summary/ (the page states "Free for use under the Pixabay Content License": free for commercial and non-commercial use, including in games; attribution not required, but we credit; may not be sold or redistributed as a standalone file).
- **File:** `music/character_select_cheerful_comedy.ogg`, **modified**: converted from the 256 kbps MP3 to Ogg Vorbis (q5), otherwise unaltered. Imported with Loop on. Played by the `Audio` autoload (`MENU_MUSIC`) on the start menu and character select; it fades out when the character is destroyed.

Credit line:

> "Cheerful Comedy Funny Quirky Background" by alex-morgan (Pixabay), Pixabay Content License

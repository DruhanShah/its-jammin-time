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
  - `creaky_door_short.wav` (pack folder `Environment/`) and `foley_creak_1.wav` (pack folder `Footsteps/`): occasional office chair caster squeak/creak (random pick, pitched up in the scene). Imported as mono.

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

Credit lines (optional under CC0):

> Screwdriver sounds by 16GPanskaToman_Kristian, bolt drop by zembacraftworks, panel clatter by ME_Studios_Official (Freesound), CC0

## Placeholders (ours)

Generated procedurally by a small Python script (sine tones and filtered noise), made for this project. No third-party or AI-generated audio. Replace them with real recordings when ready.

- `music/placeholder_loop.wav`: 8 s quiet sine-chord loop (C, Am, F, G).
- `narrator/placeholder_desk_intro.wav`: ~3 s of speech-like beeps for the example narrator cue.

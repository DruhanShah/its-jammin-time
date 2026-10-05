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

## Placeholders (ours)

Generated procedurally by a small Python script (sine tones and filtered noise), made for this project. No third-party or AI-generated audio. Replace them with real recordings when ready.

- `music/placeholder_loop.wav`: 8 s quiet sine-chord loop (C, Am, F, G).
- `narrator/placeholder_desk_intro.wav`: ~3 s of speech-like beeps for the example narrator cue.

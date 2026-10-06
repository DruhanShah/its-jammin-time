# Fonts

All fonts are bundled with the game under their licences (licence text next to the font files). **Comic Sans MS itself is NOT used**: it is Microsoft's and its licence does not allow bundling it in a game; the fonts below are free look-alikes.

## Comic Neue

- **Copyright:** Copyright 2014 The Comic Neue Project Authors (https://github.com/crozynski/comicneue), by Craig Rozynski & Hrant Papazian.
- **Source:** https://github.com/google/fonts/tree/main/ofl/comicneue (also https://comicneue.com/)
- **License:** SIL Open Font License 1.1, full text in `OFL-ComicNeue.txt`. Free to bundle with the game; the font may not be sold on its own.
- **Files used:** `ComicNeue-Bold.ttf` (project-wide UI font, `core/ui/theme.tres`), `ComicNeue-Italic.ttf` (narrator subtitles), `ComicNeue-Regular.ttf`.

## Comic Relief

- **Copyright:** Copyright 2013 The Comic Relief Project Authors (https://github.com/loudifier/Comic-Relief), by Jeff Davis.
- **Source:** https://github.com/google/fonts/tree/main/ofl/comicrelief (from google/fonts)
- **License:** SIL Open Font License 1.1, full text in `OFL-ComicRelief.txt`.
- **Files used:** `ComicRelief-Bold.ttf` (3D signs in the office, EXIT signs, word processor buttons), `ComicRelief-Regular.ttf` (also what the word processor's "Comic Sans" font option renders with: Comic Relief is metric-compatible with Comic Sans MS. The font file is unmodified; "Comic Sans" is only the menu label, no Microsoft font is included).

## Comic Shanns Mono

- **Copyright:** Copyright (c) 2018 Shannon Miwa, Copyright (c) 2023 Jesus Gonzalez (https://github.com/jesusmgg/comic-shanns-mono).
- **License:** MIT License, full text in `LICENSE-ComicShannsMono.md`.
- **Files used:** `ComicShannsMono-Regular.ttf` (the word processor's default document font, ruler and status bar).

## Look-alike fonts for the font picker's wrong options

The word processor's font list (`minigames/computer/minigames/font_picker/font_picker.gd`) shows each wrong option in a free look-alike so it renders the same on every platform, web included. The menu labels are the real font names only; none of those fonts are included.

Times New Roman, Arial, Helvetica, Calibri, Papyrus, Impact, Wingdings and Comic Sans are trademarks of their respective owners. None of those fonts are included; the menu shows free look-alike fonts.

### Tinos

- **Copyright:** Copyright 2026 The Tinos Project Authors (https://github.com/googlefonts/tinos).
- **License:** SIL Open Font License 1.1, full text in `OFL-tinos.txt`.
- **Modifications:** subset to Latin.
- **Files used:** `Tinos-Regular-Latin.ttf` (the "Times New Roman" option).

### Arimo

- **Copyright:** Copyright 2026 The Arimo Project Authors (https://github.com/googlefonts/arimo).
- **License:** SIL Open Font License 1.1, full text in `OFL-arimo.txt`.
- **Modifications:** Regular instance of the variable font, subset to Latin.
- **Files used:** `Arimo-Regular-Latin.ttf` (the "Arial" and "Helvetica" options).

### Office Sans Jam (modified Carlito)

- **Copyright:** Copyright 2013 The Carlito Project Authors (https://github.com/googlefonts/carlito), Reserved Font Name "Carlito".
- **License:** SIL Open Font License 1.1, full text in `OFL-carlito.txt`.
- **Modifications:** subset to Latin and renamed to "Office Sans Jam", as the Reserved Font Name requires for a modified version.
- **Files used:** `OfficeSans-Regular-Latin.ttf` (the "Calibri" option).

### EB Garamond

- **Copyright:** Copyright 2017 The EB Garamond Project Authors (https://github.com/octaviopardo/EBGaramond12).
- **License:** SIL Open Font License 1.1, full text in `OFL-ebgaramond.txt`.
- **Modifications:** Regular instance of the variable font, subset to Latin.
- **Files used:** `EBGaramond-Regular-Latin.ttf` (the "Garamond" option).

### Almendra

- **Copyright:** Copyright (c) 2011-2012, Ana Sanfelippo (anasanfe@gmail.com), with Reserved Font Name 'Almendra'.
- **License:** SIL Open Font License 1.1, full text in `OFL-almendra.txt`.
- **Modifications:** none (unmodified).
- **Files used:** `Almendra-Regular.ttf` (the "Papyrus" option).

### Anton

- **Copyright:** Copyright 2020 The Anton Project Authors (https://github.com/googlefonts/AntonFont.git).
- **License:** SIL Open Font License 1.1, full text in `OFL-anton.txt`.
- **Modifications:** subset to Latin.
- **Files used:** `Anton-Regular-Latin.ttf` (the "Impact" option).

### Jamdings

- **Copyright:** glyphs Copyright 2022 The Noto Project Authors (https://github.com/notofonts/symbols), from Noto Sans Symbols and Noto Sans Symbols 2.
- **License:** SIL Open Font License 1.1, full text in `OFL-Jamdings-NotoSymbols.txt`.
- **Modifications:** glyphs scaled and mapped to letters by the team.
- **Files used:** `Jamdings-Regular.ttf` (the "Wingdings" option).

## DejaVu Sans

- **Copyright:** Bitstream Vera Fonts Copyright (c) 2003 by Bitstream, Inc.; DejaVu changes are in the public domain (https://dejavu-fonts.github.io/).
- **License:** Bitstream Vera / DejaVu font licence (free to bundle), full text in `LICENSE-DejaVu.txt`.
- **Files used:** `DejaVuSans-Bold.ttf`, unmodified: fallback for symbols the other fonts lack (● ✓ ♥ ⌫ ∞ → ▌), set in `core/game_state.gd`. The web build has no system fonts to fall back on.

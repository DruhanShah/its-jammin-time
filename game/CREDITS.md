# Credits and third-party resources

Every external resource in this project. "Shipped" = ends up in the exported game; "editor-only" = only used while developing (not loaded at runtime). Per-folder `CREDITS.md` files have details. Comic Sans MS itself is NOT used (Microsoft licence, can't be bundled); the Comic fonts below are free look-alikes.

| Resource | Author | Source | License | Where | Shipped? |
|---|---|---|---|---|---|
| Godot Engine 4.7 | Juan Linietsky, Ariel Manzur and Godot Engine contributors | https://godotengine.org/ | MIT (engine + its bundled third-party libs, see https://godotengine.org/license/) | the engine/export templates | Shipped |
| Godot logo (`icon.svg`, default project icon) | Andrea Calabró | https://godotengine.org/press/ | CC BY 4.0 | `icon.svg` | Shipped (project icon) |
| Low Poly 3D Office Set [VNB] v1.1.0 | VNB (Leo), https://vnbp.itch.io/ | https://vnbp.itch.io/low-poly-3d-office-set-vnb | CC BY 4.0 (attribution required; no reselling the models) | `assets/vnb_office/` ([CREDITS](assets/vnb_office/CREDITS.md)) | Shipped |
| Comic Neue (Bold, Italic, Regular) | Craig Rozynski & Hrant Papazian; Copyright 2014 The Comic Neue Project Authors | https://github.com/crozynski/comicneue | SIL Open Font License 1.1 (`OFL-ComicNeue.txt`) | `assets/fonts/` ([CREDITS](assets/fonts/CREDITS.md)) | Shipped |
| Comic Relief (Bold, Regular) | Jeff Davis; Copyright 2013 The Comic Relief Project Authors | https://github.com/loudifier/Comic-Relief (from google/fonts) | SIL Open Font License 1.1 (`OFL-ComicRelief.txt`) | `assets/fonts/` ([CREDITS](assets/fonts/CREDITS.md)) | Shipped |
| Comic Shanns Mono (Regular) | Copyright (c) 2018 Shannon Miwa, Copyright (c) 2023 Jesus Gonzalez | https://github.com/jesusmgg/comic-shanns-mono | MIT (`LICENSE-ComicShannsMono.md`) | `assets/fonts/` ([CREDITS](assets/fonts/CREDITS.md)) | Shipped |
| 400 Sounds Pack (13 files) | Chequered Ink, https://ci.itch.io/ | https://ci.itch.io/400-sounds-pack | Free for any use incl. commercial, credit optional; may not sell/redistribute the unaltered assets as your own assets (verbatim text in [CREDITS](assets/audio/CREDITS.md)) | `assets/audio/sfx/400_sounds_pack/` | Shipped |
| "rolling_office_chair.WAV" (trimmed into a 3 s loop) | alpanaytekin | https://freesound.org/people/alpanaytekin/sounds/213086/ | CC0 1.0 (public domain) | `assets/audio/sfx/chair_roll_loop.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| PSX First Person Arms (Free) v1.1.0 | Drillimpact, https://drillimpact.itch.io/ | https://drillimpact.itch.io/psx-first-person-arms-free | CC0 (public domain) | `assets/models/arms/` ([CREDITS](assets/models/arms/CREDITS.md)) | Shipped |
| "Screwdriver" 3D model | CreativeTrio | https://poly.pizza/m/qBFMjkrKzH | CC0 1.0 (public domain) | `assets/models/screwdriver/` ([CREDITS](assets/models/screwdriver/CREDITS.md)) | Shipped |
| "Screwdriver 1" (2 clicks cut from it) | 16GPanskaToman_Kristian | https://freesound.org/people/16GPanskaToman_Kristian/sounds/496286/ | CC0 1.0 | `assets/audio/sfx/freesound/screw_click_*.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| "Bolts into Iron Pipe Flange" (cut) | zembacraftworks | https://freesound.org/people/zembacraftworks/sounds/428340/ | CC0 1.0 | `assets/audio/sfx/freesound/screw_drop_bolt_zemba.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| Vent cover removal (cut) | ME_Studios_Official | https://freesound.org/people/ME_Studios_Official/sounds/649765/ | CC0 1.0 | `assets/audio/sfx/freesound/panel_clatter_vent_me_studios.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| "Electricity Sound" (cut) | NachtmahrTV | https://freesound.org/people/NachtmahrTV/sounds/556717/ | CC0 1.0 | `assets/audio/sfx/freesound/spark_crackle_nachtmahr.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| 400 Sounds Pack, computer UI sounds (`pop_2`, `whoosh_1`, `power_down`; same pack and licence as above) | Chequered Ink, https://ci.itch.io/ | https://ci.itch.io/400-sounds-pack | as above | `assets/audio/sfx/400_sounds_pack/` | Shipped |
| Godot AI 4.3.0 (MCP editor bridge) | Godot AI contributors | https://github.com/hi-godot/godot-ai | MIT (`addons/godot_ai/LICENSE`) | `addons/godot_ai/` | Editor-only (its export plugin strips the `_mcp_game_helper` autoload) |
| Godot Asset Placer 1.6.0 | Roman Levinzon (levinzonr) | https://github.com/levinzonr/godot-asset-placer | MIT (`addons/asset_placer/LICENSE`) | `addons/asset_placer/` | Editor-only |
| Snappy / godot-snappy 0.1.0 (main @ 4fdaaa3) | Jakob Gillich (jgillich) | https://github.com/jgillich/godot-snappy | MIT (`addons/snappy/LICENSE`) | `addons/snappy/` | Editor-only |

## Made for this project (ours)

- Placeholder music and narrator audio (`assets/audio/music/`, `assets/audio/narrator/`): generated procedurally, see [audio CREDITS](assets/audio/CREDITS.md).
- Ceiling grid texture (`world/office/textures/ceiling_grid.png`): 128x128 generated grid.
- Cartoon glove mouse cursor (`core/ui/comic/cursor/glove.svg`, `glove_tap.svg`): hand-written SVG drawn for this project.
- Halftone (Ben-Day dots) shader (`core/ui/comic/halftone.gdshader`): written for this project.
- All scripts, scenes, materials and narration cues outside `addons/`.

## Credits screen text (suggested)

> Low Poly 3D Office Set by VNB (Leo), https://vnbp.itch.io/, licensed under CC BY 4.0
> Comic Neue: Copyright 2014 The Comic Neue Project Authors (https://github.com/crozynski/comicneue), by Craig Rozynski & Hrant Papazian. SIL Open Font License 1.1.
> Comic Relief: Copyright 2013 The Comic Relief Project Authors (https://github.com/loudifier/Comic-Relief), by Jeff Davis. SIL Open Font License 1.1.
> Comic Shanns Mono: Copyright (c) 2018 Shannon Miwa, Copyright (c) 2023 Jesus Gonzalez (https://github.com/jesusmgg/comic-shanns-mono). MIT License.
> (Comic Sans MS is not used; it is licensed by Microsoft.)
> Sound effects from 400 Sounds Pack by Chequered Ink, https://ci.itch.io/
> Rolling chair sound by alpanaytekin (Freesound), CC0
> First-person arms: PSX First Person Arms by Drillimpact, https://drillimpact.itch.io/, CC0
> Screwdriver model by CreativeTrio (Poly Pizza), CC0
> Screwdriver sounds by 16GPanskaToman_Kristian, bolt drop by zembacraftworks, panel clatter by ME_Studios_Official (Freesound), CC0
> Electricity crackle by NachtmahrTV (Freesound), CC0
> Made with Godot Engine, https://godotengine.org/license/

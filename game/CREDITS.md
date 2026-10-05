# Credits and third-party resources

Every external resource in this project. "Shipped" = ends up in the exported game; "editor-only" = only used while developing (not loaded at runtime). Per-folder `CREDITS.md` files have details.

| Resource | Author | Source | License | Where | Shipped? |
|---|---|---|---|---|---|
| Godot Engine 4.7 | Juan Linietsky, Ariel Manzur and Godot Engine contributors | https://godotengine.org/ | MIT (engine + its bundled third-party libs, see https://godotengine.org/license/) | the engine/export templates | Shipped |
| Godot logo (`icon.svg`, default project icon) | Andrea Calabró | https://godotengine.org/press/ | CC BY 4.0 | `icon.svg` | Shipped (project icon) |
| Low Poly 3D Office Set [VNB] v1.1.0 | VNB (Leo), https://vnbp.itch.io/ | https://vnbp.itch.io/low-poly-3d-office-set-vnb | CC BY 4.0 (attribution required; no reselling the models) | `assets/vnb_office/` ([CREDITS](assets/vnb_office/CREDITS.md)) | Shipped |
| Comic Neue (Bold) | Craig Rozynski and The Comic Neue Project Authors | https://github.com/google/fonts/tree/main/ofl/comicneue | SIL Open Font License 1.1 (`OFL.txt`) | `assets/fonts/` ([CREDITS](assets/fonts/CREDITS.md)) | Shipped |
| 400 Sounds Pack (8 files) | Chequered Ink, https://ci.itch.io/ | https://ci.itch.io/400-sounds-pack | Free for any use incl. commercial, credit optional; may not sell/redistribute the unaltered assets as your own assets (verbatim text in [CREDITS](assets/audio/CREDITS.md)) | `assets/audio/sfx/400_sounds_pack/` | Shipped |
| "rolling_office_chair.WAV" (trimmed into a 3 s loop) | alpanaytekin | https://freesound.org/people/alpanaytekin/sounds/213086/ | CC0 1.0 (public domain) | `assets/audio/sfx/chair_roll_loop.wav` ([CREDITS](assets/audio/CREDITS.md)) | Shipped |
| PSX First Person Arms (Free) v1.1.0 | Drillimpact, https://drillimpact.itch.io/ | https://drillimpact.itch.io/psx-first-person-arms-free | CC0 (public domain) | `assets/models/arms/` ([CREDITS](assets/models/arms/CREDITS.md)) | Shipped |
| Godot AI 4.3.0 (MCP editor bridge) | Godot AI contributors | https://github.com/hi-godot/godot-ai | MIT (`addons/godot_ai/LICENSE`) | `addons/godot_ai/` | Editor-only (its export plugin strips the `_mcp_game_helper` autoload) |
| Godot Asset Placer 1.6.0 | Roman Levinzon (levinzonr) | https://github.com/levinzonr/godot-asset-placer | MIT (`addons/asset_placer/LICENSE`) | `addons/asset_placer/` | Editor-only |
| Snappy / godot-snappy 0.1.0 (main @ 4fdaaa3) | Jakob Gillich (jgillich) | https://github.com/jgillich/godot-snappy | MIT (`addons/snappy/LICENSE`) | `addons/snappy/` | Editor-only |

## Made for this project (ours)

- Placeholder music and narrator audio (`assets/audio/music/`, `assets/audio/narrator/`): generated procedurally, see [audio CREDITS](assets/audio/CREDITS.md).
- Ceiling grid texture (`world/office/textures/ceiling_grid.png`): 128x128 generated grid.
- All scripts, scenes, materials and narration cues outside `addons/`.

## Credits screen text (suggested)

> Low Poly 3D Office Set by VNB (Leo), https://vnbp.itch.io/, licensed under CC BY 4.0
> Comic Neue by Craig Rozynski, SIL Open Font License 1.1
> Sound effects from 400 Sounds Pack by Chequered Ink, https://ci.itch.io/
> Rolling chair sound by alpanaytekin (Freesound), CC0
> First-person arms: PSX First Person Arms by Drillimpact, https://drillimpact.itch.io/, CC0
> Made with Godot Engine, https://godotengine.org/license/

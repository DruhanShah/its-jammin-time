# Placing office assets in the map

How to get the VNB office models (desks, chairs, plants, printers…) into `office.tscn` neatly. All shortcuts are for macOS.

## Further reading

- [Introduction to 3D (official docs)](https://docs.godotengine.org/en/stable/tutorials/3d/introduction_to_3d.html): the 3D viewport, gizmos, navigation, the Transform menu (Snap Object to Floor, Configure Snap) and snapping. Read this one first.
- [Creating instances (official docs)](https://docs.godotengine.org/en/stable/getting_started/step_by_step/instancing.html): what an "instance" is. Every desk you drop in is an instance of the imported model.
- [Import configuration (official docs)](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html): why you shouldn't edit an imported `.fbx` directly, and when to use inherited scenes.
- [Advanced Import Settings (official docs)](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/advanced_import_settings.html): the per-mesh "Generate > Physics" options we use to get collision.
- [Default editor shortcuts (official docs, 4.4 page)](https://docs.godotengine.org/en/4.4/tutorials/editor/default_key_mapping.html): every shortcut, with a macOS column. The stable URL for this page currently returns 404, so this link points at the 4.4 version, which is still accurate.

## How our assets are set up

- **Models:** `res://assets/vnb_office/models/*.fbx` holds 170 low-poly models. Godot imports each one as a scene, so you can drag it in like any `.tscn`.
- **Materials:** the models share a few external materials in `assets/vnb_office/materials/` (`palette.tres`, `screen.tres`, …). Each `.fbx.import` file maps them like this:
  ```
  "Palette": { "use_external/enabled": true, "use_external/path": "res://assets/vnb_office/materials/palette.tres" }
  ```
  Changing `palette.tres` recolours every model at once.
- **Collision is automatic.** Every `.fbx.import` sets `"generate/physics": true` on its mesh node, so each model is imported with a `StaticBody3D` and a collision shape. You don't need to add any collision yourself.
  - The shape is a **trimesh** (exact copy of the mesh). Floors, walls and static furniture (desks, counters, shelves, cabinets, tables, whiteboards) pin it with `"physics/shape_type": 2` (Trimesh). Everything else is left on the default "Automatic", which also gives a trimesh for a static body.
  - Trimesh shapes only work on static bodies. If a prop needs to be picked up or knocked over later (a `RigidBody3D`), switch its shape type to Single Convex or Box in Advanced Import Settings.
- **Grid and origins:**
  - Walls and floor tiles are 2 m pieces with their origin at a **corner**. In the room they are painted with GridMaps (see [Painting walls and floors with the GridMap](#painting-walls-and-floors-with-the-gridmap)), which handles the corner origin for you.
  - The room spans x and z from −5 to 5. The ceiling is at y = 3.875. Walls are scaled 1.29× on Y so they reach the ceiling.
  - Furniture has its origin **centred at its base**. For example, the test desk `Office_Desk_1` is at `(0, 0, -3)`.
- **Scene tree:** `Office` → `WorldEnvironment`, `Floor` (GridMap), `Player`, `Walls` (GridMap), `Ceiling`, `CeilingLights`, `Furniture` (`Office_Desk_1`, `Computer`), `DeskNarratorTrigger`.

## Step by step

1. **Open the map.** In the FileSystem dock, double-click `world/office/office.tscn`.
2. **Pick a group for props.** Furniture goes under the `Furniture` node.
   - To add another group (e.g. `Decor`, `Electronics`), select `Office`, press **Cmd+A**, choose **Node3D** and rename it.
   - Keep the group nodes at position (0, 0, 0) so child positions stay in world coordinates.
3. **Add a model.**
   - Select the group node in the Scene dock.
   - Drag an `.fbx` (e.g. `Chair_Office_Base_A.fbx`) from the FileSystem dock into the **3D viewport**. It lands where the mouse points.
   - Or drag it onto the group node in the **Scene dock**, which places it at the group's origin.
   - Or, with the group selected, press **Cmd+Shift+A** (Instantiate Child Scene) and pick the file.
4. **Move and rotate.**
   - Press **W** for move or **E** for rotate, then drag the coloured gizmo handles (red = X, green = Y, blue = Z).
   - Press **F** to focus the camera on the selection.
   - Hold the right mouse button and use WASD to fly around. Q and E move you down and up while flying.
   - For exact values, type them in Inspector → Node3D → Transform → Position / Rotation.
5. **Snapping.**
   - Press **Y** to toggle snapping, or hold **Cmd** while dragging to snap just for that drag.
   - Set the step sizes in the viewport toolbar under **Transform → Configure Snap…**:

     | Placing | Translate | Rotate |
     |---|---|---|
     | Walls / floor tiles (2 m grid) | `2` | `90` |
     | Furniture | `0.5` (or `0.25` for tight layouts) | `15`, or `90` to line up with walls |
     | Small desk items (cups, pens, staplers) | snapping off, or `0.05` | `15` |

   - Snapping moves the object in steps from where it **started**; it doesn't jump to absolute grid lines. For walls and floor tiles, use the GridMap instead (see below).
   - Tile centres are at even coordinates (−4, −2, 0, 2, 4). With 0.5 m snapping, furniture lines up with both tile centres and tile edges.
6. **Snap to floor.** Select an object and press **PageDown** (**Fn+↓** on a MacBook keyboard), or use **Transform → Snap Object to Floor**.
   - This drops the object onto the nearest collision surface below it.
   - It's ideal for putting a monitor or cup on a desk, because the desk has generated collision.
7. **Duplicate.**
   - **Cmd+D** duplicates the selection in place. Move the copy with the gizmo.
   - To make a row of chairs, duplicate and then move by snapped steps.
8. **Rename.**
   - Select a node and press **Return** (or double-click it), then give it a name that says what it is: `Desk_Player`, `Chair_Boss`, `Plant_Lobby`.
   - Godot names duplicates `Office_Desk_2`, `Office_Desk_3`, … These names clash with the model names (there really is an `Office_Desk_2.fbx`), so rename anything that matters.
   - To rename several nodes at once, select them and press **Cmd+F2** (Batch Rename).
9. **Check collision.**
   - Press **Cmd+R** to run the current scene and walk into the object. You should be blocked.
   - To see the collision shapes, enable **Debug → Visible Collision Shapes** in the top menu before running.
10. **Save** with **Cmd+S**. Then commit. Small, frequent commits avoid painful `.tscn` merge conflicts.

## Editor plugins: Asset Placer and Snappy

Both plugins are in `game/addons/` and already enabled (**Project → Project Settings → Plugins**). They are editor-only and add nothing to the game: the export preset excludes `addons/asset_placer/`, `addons/snappy/` and `addons/godot_ai/` from builds.

### Asset Placer (click to place models)

[Godot Asset Placer](https://github.com/levinzonr/godot-asset-placer) adds an **Asset Placer** tab to the bottom panel (next to Output / Debugger).

1. **Our models are already in the library.** The team shares one library (see below) that already contains the `res://assets/vnb_office/models` folder, so the 170 models show up in the **Assets** tab. Thumbnails are generated on your machine the first time you open the tab. If the tab is empty, restart the editor.
2. **Set the options** (Options panel in the same tab):
   - **Assets Parent:** pick `Furniture` (or tick **Resolve Parent from Selected Nodes** to place next to whatever is selected).
   - **Randomize Rotation On Placement:** turn it **off**. It is on by default (every editor start) and spins every desk to a random angle.
   - **Auto-Group by Collections:** turn it off unless you use collections; otherwise it creates extra group nodes.
   - **Grid Snapping:** on, **Grid Step** `0.5` for furniture (lines up with tile centres and edges, see the table above). The grid is absolute, from the world origin. Don't use it for 2 m floor/wall pieces: their origin is at a corner on odd coordinates, which a 2 m step can't reach (step `1` works).
   - **Placement Mode:** Surface Collisions (default). Our models have generated collision, so you can place a monitor straight onto a desk.
3. **Place.** With `office.tscn` open, click an asset in the **Assets** tab; a preview follows the mouse in the 3D viewport. **Left click** places it, **Shift+Left click** places it and selects it for normal editing. Press **Esc** or **Shift+A** to leave placement mode.
4. **Before placing:** **E** rotate, **R** scale, **W** move along an axis (switches to plane mode); pick the axis with **X / Y / Z**, then use the **mouse wheel** (5° / 0.1 m per notch, change in Settings). **Q** cycles placement modes, **S** toggles grid snapping. These keys replace Godot's own shortcuts only while placement mode is active.
5. **Existing nodes:** select one and press **Shift+E** (In Place Transform) to use the same keys + mouse wheel on it.
6. Placements go through undo (**Cmd+Z**) like normal edits.

Where it keeps its data:
- **Asset library (folders, assets, tags, collections) is shared:** `res://assets/asset_placer_library.json`, committed. The path is the project setting `asset_placer/general/asset_library_path` in `project.godot` (**Settings → Asset Library Path** in the plugin). If you add a folder, tag or collection, commit the JSON too. The plugin writes it as one long line, so if two people change it at once, take one version and re-add the other person's change in the editor rather than merging by hand.
- Per person, outside the repo (`user://` = `~/Library/Application Support/Godot/app_userdata/Infinium Game Jam/` on macOS): palettes and "last placed" → `user://asset_placer_editor_settings.tres`; thumbnails → `user://asset_placer/thumbnails`.
- Key bindings and transform steps → Godot's Editor Settings (per machine, all projects).
- The placement options (Assets Parent, Randomize Rotation, Grid Snapping, …) aren't saved anywhere: they reset every time the editor starts, so turn **Randomize Rotation On Placement** off again each session.
- The plugin and its library JSON are excluded from exported builds (`exclude_filter` in `game/export_presets.cfg`).
- It checks GitHub for updates when the editor starts. Don't click its in-editor update button unless the team agrees, since that replaces `addons/asset_placer/`.

### Snappy (vertex snapping)

[godot-snappy](https://github.com/jgillich/godot-snappy) snaps one object's vertex onto another's, e.g. a wall piece flush against the next one or a monitor's corner against a desk edge.

1. Select an object in the 3D viewport.
2. Hold **V**. A yellow dot shows the vertex of the selection that is nearest the mouse.
3. Keep holding **V** and **left-drag**: the object moves so that vertex sits on the nearest vertex of the mesh under the mouse. Release to finish (undo with **Cmd+Z**).

The move/rotate gizmo can get in the way; press **Q** (select mode) first, or start the drag away from the gizmo. Move the mouse once after pressing V if the dot doesn't appear.

## Painting walls and floors with the GridMap

The office's floor and walls are two [GridMap](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html) nodes, `Floor` and `Walls`. Each one paints pieces from the same MeshLibrary, `world/office/gridmap/structure_library.tres`. The pieces are: `Floor`, `Wall`, `WallDoorway`, `WallPanelledA/B`, `WallPillar`, `Partition`, `PartitionDoorway`, `PartitionLow` and `Ceiling`. The pack has no window walls.

**How the grid works:**
- A cell is 2 × 3.875 × 2 m: one floor tile, one storey high.
- Both GridMaps sit at `(-1, 0, -1)`, so cell `(i, 0, k)` is centred on world `(2i, 0, 2k)`. The room is cells −2…2.
- A wall piece sits on the **north edge** of its cell. Rotate it to put it on another edge.
- A cell holds one piece. That's why floors and walls live in separate GridMaps.
- If a corner cell needs two walls, paint the second one in the neighbouring cell, rotated to face back. The room's west and east walls live in the column just outside the room.

**Painting** (shortcuts are the same on macOS; they only apply while a GridMap is selected and the mouse is over the 3D viewport):
1. Select `Walls` (or `Floor`) in the Scene dock. The **GridMap** panel opens at the bottom with the pieces, and a GridMap toolbar appears above the viewport.
2. Click a piece in the panel, then press **E** (Paint). **Left click** or drag in the viewport paints. Hold the right mouse button to fly around as usual.
3. **S** rotates the piece 90° around Y before you click; **A** / **D** rotate around X / Z (not needed for us). **Option+G** clears the rotation.
4. **W** (Erase) + left click removes pieces. **R** (Pick) copies the piece and rotation under the mouse. **Q** selects an area, then **Z** fills, **X** moves, **C** duplicates or **V** deletes it.
5. **Change floor level:** **1** / **3**, **Cmd+mouse wheel**, or the Floor box in the GridMap toolbar. Level 1 starts at y = 3.875, right above our ceiling.
6. Paint walls into `Walls` and floors into `Floor`. Don't stack them in one GridMap. Save with **Cmd+S**. Collision comes with the pieces (layer 1, same as before).

**Adding a piece to the library:**
1. Open `world/office/gridmap/structure_library_source.tscn`. Each piece is a `MeshInstance3D` (its name becomes the item name) with a `StaticBody3D` → `CollisionShape3D` child. The pieces are spread out under `…Slot` nodes so you can see them; the export ignores the slots' positions.
2. Drag the `.fbx` in under the root, right-click it → **Make Local**, and rename the inner `MeshInstance3D` to the item name. Its imported `StaticBody3D` child already has the right structure.
3. Select the inner `MeshInstance3D` and set its Transform. Position `(-1, 0, -1)` puts a corner-origin piece inside the cell (on its north edge for walls). For a full-height wall, also set Scale Y `1.2916667`. To recolour, set Surface Material Override.
4. **Scene → Export As… → MeshLibrary…**, pick `structure_library.tres`, tick **Apply MeshInstance Transforms** (off by default; without it every piece lands one metre off), and leave **Merge With Existing** on so the existing item IDs (and every painted cell) stay the same. Then save.

## Making a reusable prop scene (for interactables)

If an object needs behaviour, such as the useless button, the light switch or the binoculars, wrap it in a scene of its own. Don't edit the model. This follows the same pattern as `world/office/parts/ceiling_light.tscn`.

1. **Scene → New Scene → Other Node**, and choose `Node3D` as the root. Name it after the prop, e.g. `LightSwitch`.
2. Drag the `.fbx` in as a child. Its collision comes with it.
3. If the player needs to interact with it, add an `Area3D` with a `CollisionShape3D` child.
4. Attach a script to the root.
5. Save it as `world/office/props/light_switch.tscn` (or `parts/`).
6. Instance that `.tscn` into `office.tscn` instead of the raw `.fbx`. Changes you make to the prop scene then show up in every copy.

The alternative is right-click the `.fbx` → **New Inherited Scene**. That's useful if you need to change the model's own nodes. The wrapper scene above is simpler and survives re-imports better.

## Common pitfalls

- **Editing the imported model directly.** Opening an `.fbx` and changing it shows a warning, and your changes are thrown away on re-import. Change import options through the Import dock or Advanced Import Settings (double-click the `.fbx`). Change behaviour through a wrapper scene.
- **"Editable Children" on an instance.** This lets you poke inside one copy, but it's easy to forget and hard to track. Prefer a wrapper scene.
- **Scale.** The models are already in metres, so leave scale at `1, 1, 1` for furniture. Scaling a model also scales its collision. A 2× desk is a 2× wall the player bumps into. Only the walls are intentionally stretched on Y.
- **Floating or sinking objects.** Furniture should have y = 0 when it stands on the floor, or press PageDown. If something floats after snapping to floor, it probably landed on another object's collision. Check with Visible Collision Shapes.
- **Rotation drift.** Free-rotating without snapping leaves angles like 89.7°. Turn snapping on (Y), or type `0/90/180/270` in the Inspector.
- **Too many lights.** We use the Compatibility renderer, which shades each mesh with a limited number of lights.
  - We raised **Project Settings → Rendering → Limits → OpenGL → Max Lights Per Object** to `16`. There are 9 ceiling spotlights today.
  - If you add lamps (`Lamp_1.fbx` plus an `OmniLight3D`) or more `CeilingLight`s, a large object like a floor tile can exceed that limit. Some lights will then silently stop affecting it.
  - The GridMaps merge their pieces into big chunks (an octant is 8×8×8 cells, so the whole room is only a few objects). Every light in the room counts against each chunk, so keep the total lights in a room under 16, or lower the GridMap's **Cell → Octant Size**.
  - Raise the limit, or split big meshes. Also keep an eye on **Max Renderable Lights** in the same section.
- **Lost in the tree.** Always select the right group before adding. Collapse groups you're not working on. Use the Scene dock's filter box to find nodes by name.

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
- **Grid and origins:**
  - Walls and floor tiles are 2 m pieces with their origin at a **corner**. Floor tiles sit at y = 0, and their corners are on odd coordinates (−5, −3, …, 3).
  - The room spans x and z from −5 to 5. The ceiling is at y = 3.875. Walls are scaled 1.29× on Y so they reach the ceiling.
  - Furniture has its origin **centred at its base**. For example, the test desk `Office_Desk_1` is at `(0, 0, -3)`.
- **Scene tree:** `Office` → `WorldEnvironment`, `Floor`, `Walls`, `Ceiling`, `CeilingLights`, `Player`, `Office_Desk_1`.

## Step by step

1. **Open the map.** In the FileSystem dock, double-click `world/office/office.tscn`.
2. **Make a group for props (first time only).** Furniture currently sits loose under the root.
   - Select `Office`, press **Cmd+A**, choose **Node3D** and rename it `Furniture`. You could also add groups like `Decor` and `Electronics`.
   - Drag `Office_Desk_1` onto `Furniture`.
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

   - Snapping moves the object in steps from where it **started**; it doesn't jump to absolute grid lines. Before using 2 m snapping on a wall, type a position that's already on the grid (odd x/z values, y = 0).
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
  - Raise the limit, or split big meshes. Also keep an eye on **Max Renderable Lights** in the same section.
- **Lost in the tree.** Always select the right group before adding. Collapse groups you're not working on. Use the Scene dock's filter box to find nodes by name.

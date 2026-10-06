# Furnishing plan (phase 2a)

What goes in each room of `game/world/office/office.tscn`, with positions you can type in. Read [`README.md`](README.md) for the room grid and doors and [`furnishing_guide.md`](furnishing_guide.md) for model sizes and facing. Part 1 (prefabs + Start, A2, A1, A3, B2, B1, B3) and part 2 (C1, C2, C3) are built; see [As built (part 1)](#as-built-part-1) and [As built (part 2)](#as-built-part-2) at the end for what changed.

## Conventions

- **Coordinates are room-local**, for children of `Rooms/<Room>/Furniture`: x −6…6 (east +), z −8…8 (south +), y up. Inner wall faces are at x ±5.9 and z ±7.9. The ceiling is at y 3.875.
- **Rotation** is `rotation_degrees` (X, Y, Z), Godot's default YXZ order. Rot Y = θ turns a model's +Z (screen / desk knee side / the way a chair's sitter looks) toward (sin θ, 0, cos θ): **0 = south, 90 = east, 180 = north, 270 = west**. A chair faces its desk with rot = desk rot + 180 and sits 0.75 m out from the desk's knee side.
- **Upside down** = rot (0, θ, 180) with the origin at y 3.875. The item keeps its facing θ and hangs from the ceiling.
- **Wall items** are centred on the given point and sit flush with the inner wall face: north wall rot Y 0, south 180, west 90, east 270. A tilt is rot Z (e.g. (0, 90, 6) = 6° crooked on the west wall).
- **Groups:** a row in **bold** is a plain Node3D under `Furniture`. Rows marked ↳ under it are its children, in group-local coordinates.
- Model names without a path mean `res://assets/vnb_office/models/<Name>.fbx`. Chairs are always `res://world/office/props/office_chair.tscn` (`model`: 0 Task/blue, 1 Armchair/black, 2 Executive). They are pushable unless marked **freeze = true**.
- **Walkways and doors:** each room has 2.8 m wide keep-clear walkways (z −0.4…2.4 east–west, x −0.4…2.4 north–south) joining its doorways, and nothing stands within 1.5 m of a doorway centre. Doorways are always at local z = 1 on the east/west walls and x = 1 on the north/south walls. **Every doorway gets an openable door** (frame + ~1 m leaf swinging up to 90°, built as a separate prop before furnishing). So the 1.5 m radius around each doorway centre is kept clear on **both** sides of the wall for the leaf's swing. No wall item hangs within 1.2 m of a doorway's edge either, so a leaf opened flat to 90° never clips a painting or clock. Every floor position below was checked against these zones, the walls and other items with a script (footprints rotated, 2 cm tolerance). Ceiling items were checked against the light panels.

## Weirdness ladder (by distance from Start)

| Steps from Start | Room | Tier | Headline | Desks |
|---|---|---|---|---|
| 0 | Start | 0 normal | your office | 1 (existing) |
| 1 | A2 | 1 slightly off | spot the difference (twin desks) | 2 |
| 2 | A1 | 1 | Coworker Fern (plant employee) | 4 pinwheel |
| 2 | A3 | 1 | time-zone clock wall (all 6:57) | 4 pinwheel (mirrored) |
| 2 | B2 | 2 uncanny | Employee of the Month, everywhere | 8 (4 pairs) |
| 3 | B1 | 2 | corridor of doors to nowhere | 4 (2 pairs) |
| 3 | B3 | 2 | forced-perspective shrinking desks | 4 + 1 dollhouse |
| 3 | C2 | 3 absurd | **the whole room is on the ceiling** | 4 pinwheel (ceiling) |
| 4 | C3 | 3 | the meeting chaired by a plant; twisting pods | 8 (4 pairs) |
| 4 | C1 | 4 server | giant-PC "mainframes" + legacy mainframe + switchboard spot | 1 control desk |

Running gags that tie rooms together: the **mug** always at the same desk offset; **clocks** one minute earlier each room further out (Start 6:59 → C1 6:54); paintings that get stranger (normal → crooked → too high → sideways car → staircase → upside down → twisting).

## Prefabs to create first

Make these under `res://world/office/props/sets/`. Every room below reuses them, which keeps `office.tscn` small and lets one edit change every desk. Offsets are from `furnishing_guide.md` §3 (checked in `ws_front.png`).

| Scene | Root | Children (local pos, rot Y) | Notes |
|---|---|---|---|
| `ws_modern.tscn` | Node3D `WsModern` | `Office_Desk_1` (0,0,0); `Computer_Monitor` (0, 0.949, −0.20); `Computer_Keyboard` (0, 0.949, 0.12); `Computer_Mouse` (0.33, 0.949, 0.12); `Mug` = `CoffeeCup_Filled` (0.55, 0.949, 0.05); `Computer_Case` (0.50, 0, −0.10) | Knee side +Z. **No chair** (chairs are room nodes so they can be frozen / given models per room). |
| `ws_retro.tscn` | Node3D `WsRetro` | `Office_Desk_2` (0,0,0); `Computer_Old` (0, 0.949, −0.12); `Computer_Old_Keyboard` (0, 0.949, 0.22); `Computer_old_mouse` (0.33, 0.949, 0.22); `Mug` (0.55, 0.949, 0.05); `Computer_Case_Old` (0.50, 0, −0.10); `Phone_A_Base` (−0.5, 0.949, −0.1) | 90s CRT desk. |
| `desk_pair.tscn` | Node3D `DeskPair` | `DeskN` = ws_modern (0, 0, −0.375) rot 180; `DeskS` = ws_modern (0, 0, 0.375) rot 0; `ChairN` = office_chair (0, 0, −1.125) rot 0, model 1; `ChairS` = office_chair (0, 0, 1.125) rot 180, model 1 | Back-to-back pair, the sketch's "+". Footprint 1.48 × 3.05 m including chairs. |
| `server_rack.tscn` | **StaticBody3D** `ServerRack` | `CollisionShape3D` BoxShape3D size (0.58, 1.89, 0.96) at (0, 0.945, 0); `Body` MeshInstance3D with the `Computer_Case` mesh, **scale (3.2, 4.6, 2.6)** | Front faces +Z. Get the mesh like the chair meshes: on `Computer_Case.fbx` use the import option *Save to File* → `assets/vnb_office/meshes/Computer_Case.res`. Don't instance the FBX: its trimesh body would be non-uniformly scaled. Check the box against the mesh AABB (the case's origin may not be centred in z) and shift it if needed. |
| `server_rack_legacy.tscn` | same | same with the `Computer_Case_Old` mesh; box (0.58, 1.84, 0.96) at (0, 0.92, 0) | The beige one. |
| `pc_shelf_stack.tscn` | Node3D | 3 × `WallShelf_Box` at y 0, 0.75, 1.5; in each a `Computer_Case` at (0, y + 0.03, 0) rot 0 | Open face +Z (check; rotate 180 if the back shows). Tune the 0.03 to the shelf's floor board. |
| `wall_clock.tscn` | Node3D + small `@tool` script `wall_clock.gd` | `Face` = `Clock` (0,0,0); `MinuteHand` = `Clock_A` (0, 0, 0.03); `HourHand` = `Clock_A` (0, 0, 0.035) scale (1, 0.65, 1) | Exports `hour`, `minute`, `minutes_per_second` (0 = stopped, −1 = runs backwards). Hands: rot Z = −minute × 6 and −(hour % 12 + minute / 60) × 30 (clockwise seen from +Z). Check that the face points +Z and the hand pivot is the clock centre. |

**Painting materials** (new files, don't edit the shared `assets/vnb_office/materials/painting.tres`): `world/office/materials/painting_2.tres`, `painting_3.tres` and `painting_4.tres`, copies of `painting.tres` with `albedo_texture` = `Paintings2/3/4.png` (keep `texture_filter = 3`). Apply each as a *surface material override* on the painting's canvas surface: Editable Children → the MeshInstance3D → the surface that uses `Painting`. What's on each texture (big / Small / Small2): `Paintings` = beige abstract / teal abstract / photo of a boy in a cap; `Paintings2` = blue abstract / red-blue abstract / red-blue abstract; `Paintings3` = **lime sports car** / church / girl portrait; `Paintings4` = mountains / lighthouse / woman in a sun hat. Composite in the scratchpad: `paint_tex.png`. I assumed the UV layout is the same in all four textures; check one before using the rest. **Note: `Painting_Small2` is a standing desk photo frame (0.21 × 0.25 × 0.13, tilted back), not a wall frame.** Its origin is mid-height, so on a desk top use y = 0.949 + 0.12 = 1.069.

**Labels** (`Label3D`): font `res://assets/fonts/ComicNeue-Bold.ttf`, `font_size` 48, `pixel_size` 0.004, `outline_size` 8, dark ink colour (#222). Put them 2–4 cm in front of the wall.


## Start: Your office (tier 0)

**Headline:** nothing. One desk, one computer, one chair, one plant. It must look believable so everything later reads as *wrong*.

- **Remove the two test chairs `OfficeChair2` and `OfficeChair3`.** Decision: no second "toy" chair here (the brief says one desk + a plant). `PlayerChair` itself is still pushable, and A2 gets the toy chair instead.
- Keep `PlayerDesk`, `Computer`, `PlayerChair`, `DeskNarratorTrigger` exactly where they are. The player spawns at (−1.5, 0, −1) facing west.
- **Micro-seed:** the mug sits at desk-local (0.55, 0.949, 0.05). Every desk in the game has its mug at the same offset (it's in the `ws_modern` prefab).
- **Clock seed (optional):** this clock says 6:59. Each room further away is a minute *earlier* (A2 6:58 … C1 6:54). Nobody will notice until the narrator points it out (loop / rewind theme).

```
  +------------------------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |                        |   z=-8
  |                        |
  |                        |
  |                        |
  |                        |   z=-4
  |  PP                    |
  |  DD                    |
  |@ DDc                   |
  |      ··················|   z=+0
  |      ··················D
  |                        |
  |                        |
  |                        |   z=+4
  |                        |
  |                        |
  |                        |
  +------------------------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `P` plant, `D` desk / desk pair, `c` office chair (prop).

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| Keyboard | `Computer_Keyboard` | (-4.32, 0.949, -1) | (0, 90, 0) |  |  |
| Mouse | `Computer_Mouse` | (-4.32, 0.949, -1.33) | (0, 90, 0) |  |  |
| Mug | `CoffeeCup_Filled` | (-4.45, 0.949, -1.55) | (0, 90, 0) |  | **the seed mug**: desk-local (0.55, 0.949, 0.05), the offset every later desk reuses |
| PCCase | `Computer_Case` | (-4.6, 0, -1.5) | (0, 90, 0) |  |  |
| Plant | `Nature_Deco_3` | (-4.6, 0, -2.3) | (0, 20, 0) |  |  |
| Clock | `res://world/office/props/sets/wall_clock.tscn` | (-5.875, 2.4, -1) | (0, 90, 0) |  | shows **6:59**; optional (user asked for desk + plant only); above the monitor |
| PlayerDesk | `Office_Desk_1` | (-4.5, 0, -1) | (0, 90, 0) |  | existing, keep |
| PlayerChair | `res://world/office/props/office_chair.tscn` | (-3.75, 0, -1) | (0, 270, 0) |  | existing, keep (pushable) |


≈47 nodes added in this room.


## A2: Spot the difference (tier 1)

**Headline:** two identical "twin" desks against the north wall (identical clutter at identical offsets, chairs pulled out exactly 0.75 m). Desk 2 differs in two ways: its monitor faces the wall, and its chair has its back to the desk. Narrator: *"Spot the difference. That's it, that's the minigame. We ran out of budget."*

- Twin extras (add as children of **both** `TwinDesk1` and `TwinDesk2`, desk-local): `Lamp_1_Small` (−0.55, 0.949, −0.22), `Notepad` (−0.30, 0.949, 0.12) rot Y 15, `StickNote_1` (0.33, 0.949, −0.25).
- Difference #1: on `TwinDesk2` turn on *Editable Children* and set `Computer_Monitor` rot Y = 180.
- **Toy chair** in "timeout" facing the SE wall (pushable).
- **Door to nowhere** flush on the west wall, south of the real Start doorway, floating 10 cm (feeds the "bunch of extra doors" beat). Use the new **openable door prop** here if it can be placed flush on a wall: you press X, it swings open onto bare wall.
- Everything else is plain: bookshelf, plant, a normal painting.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |  DDDf@DDD ······    PPP|   z=-8
  |   c    c  ······       |
  |           ······       |
  |           ······       |
  |           ······       |   z=-4
  |           ······       |
  |           ······       |
  |           ······       |
  |························|   z=+0
  D························D
  |           ······       |
  |           ······       |
  |           ······       |   z=+4
  |           ······      w|
  |           ······    c  |
  |    BB     ······       |
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `c` office chair (prop), `f` file cabinet, `P` plant, `B` bookshelf.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| TwinDesk1 | `res://world/office/props/sets/ws_modern.tscn` | (-4.2, 0, -7.45) | (0, 0, 0) |  | twin; extras below |
| TwinDesk1Chair | `res://world/office/props/office_chair.tscn` | (-4.2, 0, -6.7) | (0, 180, 0) |  | model Armchair |
| TwinDesk2 | `res://world/office/props/sets/ws_modern.tscn` | (-1.8, 0, -7.45) | (0, 0, 0) |  | twin; **Computer_Monitor rot Y 180** (screen to the wall) |
| TwinDesk2Chair | `res://world/office/props/office_chair.tscn` | (-1.8, 0, -6.7) | (0, 0, 0) |  | model Armchair; **rot 0 = back to its desk** (difference #2) |
| Divider | `FileCabinet_Standard` | (-3, 0, -7.6) | (0, 0, 0) |  | between the twins |
| TimeoutChair | `res://world/office/props/office_chair.tscn` | (4.6, 0, 6.6) | (0, 0, 0) |  | model Task, pushable; faces the wall 1.3 m away, 'in timeout' |
| Plant | `Nature_Deco_3` | (5.25, 0, -7.25) | (0, 0, 0) |  |  |
| Bookshelf | `Bookshelf` | (-3.5, 0, 7.56) | (0, 180, 0) |  |  |
| Painting | `Painting` | (5.885, 1.7, 5) | (0, 270, 0) |  | default texture (beige abstract), hung straight |
| Clock | `res://world/office/props/sets/wall_clock.tscn` | (-3, 2.5, -7.875) | (0, 0, 0) |  | shows **6:58**; one minute earlier than Start |
| FakeDoorFrame | `Door_Frame` | (-5.85, 0.1, 6) | (0, 90, 0) |  | door to nowhere, flush on the wall shared with Start; pivot is the left edge so it spans z 6.0 → 4.86; **y 0.1** = floats 10 cm. Snap flush with snappy |
| FakeDoor | `Door_A` | (-5.85, 0.1, 5.92) | (0, 90, 0) |  | closed, inside the frame (centre it in the frame by eye) |


≈117 nodes added in this room.


## A1: Coworker Fern (tier 1)

**Headline:** a 4-desk pinwheel (as on the sketch). One "employee" is a potted plant sitting in an office chair, tucked in at its desk, with a glass of water instead of a mug. Narrator: *"Fern has been here longer than you. Fern got promoted."*

- Fern's chair (Desk3's chair, group-local (−0.375, 0, 1.49)) is **frozen** so the plant stays on it. The plant is a sibling of the chair, not its child (a static FBX body must not sit inside a RigidBody).
- Small gags: a 6° crooked painting, kitchenette (counters + coffee machine + microwave), printer table near the south door (2.6 m clear of it).
- Clock: 6:57.

```
  +------------------------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |      w           KK@K  |   z=-8
  |                        |
  |                        |
  |       c                |
  |   cDDDDD               |   z=-4
  |    DDDDDc              |
  |     c                  |
  |                        |
  |           ·············|   z=+0
  |           ·············D
  |           ······       |
  |           ······       |
  |W          ······       |   z=+4
  |           ······       |
  |           ······       |
  |           ······ TT  tt|
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `c` office chair (prop), `K` counter, `T` table, `t` bin, `W` whiteboard.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| **Pinwheel** (Node3D group) | – | (-2.8, 0, -3) | (0, 0, 0) | | 4-desk pinwheel (sketch). Rows marked ↳ are children in group-local coords |
| ↳ Desk1 | `res://world/office/props/sets/ws_modern.tscn` | (0.375, 0, -0.74) | (0, 180, 0) |  |  |
| ↳ Desk1Chair | `res://world/office/props/office_chair.tscn` | (0.375, 0, -1.49) | (0, 0, 0) |  | model Armchair |
| ↳ Desk2 | `res://world/office/props/sets/ws_modern.tscn` | (0.74, 0, 0.375) | (0, 90, 0) |  |  |
| ↳ Desk2Chair | `res://world/office/props/office_chair.tscn` | (1.49, 0, 0.375) | (0, 270, 0) |  | model Task |
| ↳ Desk3 | `res://world/office/props/sets/ws_modern.tscn` | (-0.375, 0, 0.74) | (0, 0, 0) |  |  |
| ↳ Desk3Chair | `res://world/office/props/office_chair.tscn` | (-0.375, 0, 1.49) | (0, 180, 0) |  | model Armchair; **FERN'S CHAIR: freeze = true** |
| ↳ Desk4 | `res://world/office/props/sets/ws_modern.tscn` | (-0.74, 0, -0.375) | (0, 270, 0) |  |  |
| ↳ Desk4Chair | `res://world/office/props/office_chair.tscn` | (-1.49, 0, -0.375) | (0, 90, 0) |  | model Executive |
| ↳ Fern | `Nature_Deco_3` | (-0.375, 0.55, 1.49) | (0, 180, 0) |  | sits on Desk3's chair like an employee (sibling of the chair, not its child) |
| ↳ FernWater | `WaterCup_Filled` | (0.175, 0.949, 0.79) | (0, 0, 0) |  | hide Desk3's mug (editable children → CoffeeCup_Filled visible = false); Fern only drinks water |
| ↳ TeamLeadVase | `Nature_Deco_2` | (0, 0, 0) | (0, 0, 0) |  | fills the hole in the middle |
| CounterL | `Office_CounterA1` | (3.5, 0, -7.57) | (0, 0, 0) |  |  |
| CounterR | `Office_CounterA1` | (4.5, 0, -7.57) | (0, 0, 0) |  |  |
| CoffeeMachine | `CoffeeMachine` | (3.5, 0.949, -7.6) | (0, 0, 0) |  |  |
| Microwave | `Microwave_Old` | (4.55, 0.949, -7.62) | (0, 0, 0) |  |  |
| PrinterTable | `Table_Box` | (3.6, 0, 7.45) | (0, 180, 0) |  |  |
| Printer | `Printer` | (3.6, 0.949, 7.4) | (0, 180, 0) |  |  |
| Bin | `TrashBin` | (5.5, 0, 7.55) | (0, 0, 0) |  |  |
| WhiteBoard | `WhiteBoard_Big` | (-5.82, 1.5, 4.5) | (0, 90, 0) |  |  |
| CrookedPainting | `Painting_Small` | (-3, 1.7, -7.88) | (0, 0, 6) |  | tilted 6° (rot Z): crooked, barely |
| Clock | `res://world/office/props/sets/wall_clock.tscn` | (4, 2.6, -7.875) | (0, 0, 0) |  | shows **6:57**; above the kitchenette |


≈202 nodes added in this room.


## A3: Time zones (tier 1)

**Headline:** a wall of five clocks with Comic Neue labels: NEW YORK, LONDON, TOKYO, HERE all show **6:57**. DEADLINE shows 6:52, already past. Narrator: *"Global offices. All of them in this room."*

- The pinwheel is the **mirror image** of A1's (it "twists" the other way). One of its desks is the retro set (`ws_retro`, CRT): "Dave refuses to upgrade."
- A painting of mountains (Paintings4) hung near the ceiling at 3.1 m, a small lounge (coffee table + two armchairs + fruit plate), bookshelves, a filing corner.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |      w    ······     vv|   z=-8
  |           ······     ff|
  |BB         ······     ff|
  |BB         ······     SS|
  |BB         ······       |   z=-4
  |           ······       |
  |           ······       |
  |           ······       |
  |           ·············|   z=+0
  |           ·············D
  |    DcDDD               |
  |   cDDDDDc              |
  |    DDDDD           T   |   z=+4
  |       c          b Tbb |
  |                        |
  |   @   @   @   @   @    |
  +------------------------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `c` office chair (prop), `B` bookshelf, `f` file cabinet, `S` cupboard, `v` vase, `T` table, `b` armchair.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| **PinwheelMirrored** (Node3D group) | – | (-2.8, 0, 3.6) | (0, 0, 0) | | mirror image of A1's pinwheel (it 'twists' the other way). Rows marked ↳ are children in group-local coords |
| ↳ Desk1 | `res://world/office/props/sets/ws_modern.tscn` | (-0.375, 0, -0.74) | (0, 180, 0) |  |  |
| ↳ Desk1Chair | `res://world/office/props/office_chair.tscn` | (-0.375, 0, -1.49) | (0, 0, 0) |  | model Armchair |
| ↳ Desk2 | `res://world/office/props/sets/ws_retro.tscn` | (-0.74, 0, 0.375) | (0, 270, 0) |  |  |
| ↳ Desk2Chair | `res://world/office/props/office_chair.tscn` | (-1.49, 0, 0.375) | (0, 90, 0) |  | model Task; Dave's chair (retro desk) |
| ↳ Desk3 | `res://world/office/props/sets/ws_modern.tscn` | (0.375, 0, 0.74) | (0, 0, 0) |  |  |
| ↳ Desk3Chair | `res://world/office/props/office_chair.tscn` | (0.375, 0, 1.49) | (0, 180, 0) |  | model Armchair |
| ↳ Desk4 | `res://world/office/props/sets/ws_modern.tscn` | (0.74, 0, -0.375) | (0, 90, 0) |  |  |
| ↳ Desk4Chair | `res://world/office/props/office_chair.tscn` | (1.49, 0, -0.375) | (0, 270, 0) |  | model Armchair |
| ↳ Vase | `Nature_Deco_2` | (0, 0, 0) | (0, 0, 0) |  | pinwheel hole |
| Clock1 | `res://world/office/props/sets/wall_clock.tscn` | (-4.5, 2.3, 7.875) | (0, 180, 0) |  | shows **6:57**; Label3D 'NEW YORK' 0.35 m below it |
| Label1 | `Label3D (built-in)` | (-4.5, 1.95, 7.86) | (0, 180, 0) |  | text 'NEW YORK', Comic Neue Bold, font_size 48, pixel_size 0.004, outline |
| Clock2 | `res://world/office/props/sets/wall_clock.tscn` | (-2.5, 2.3, 7.875) | (0, 180, 0) |  | shows **6:57**; Label3D 'LONDON' 0.35 m below it |
| Label2 | `Label3D (built-in)` | (-2.5, 1.95, 7.86) | (0, 180, 0) |  | text 'LONDON', Comic Neue Bold, font_size 48, pixel_size 0.004, outline |
| Clock3 | `res://world/office/props/sets/wall_clock.tscn` | (-0.5, 2.3, 7.875) | (0, 180, 0) |  | shows **6:57**; Label3D 'TOKYO' 0.35 m below it |
| Label3 | `Label3D (built-in)` | (-0.5, 1.95, 7.86) | (0, 180, 0) |  | text 'TOKYO', Comic Neue Bold, font_size 48, pixel_size 0.004, outline |
| Clock4 | `res://world/office/props/sets/wall_clock.tscn` | (1.5, 2.3, 7.875) | (0, 180, 0) |  | shows **6:57**; Label3D 'HERE' 0.35 m below it |
| Label4 | `Label3D (built-in)` | (1.5, 1.95, 7.86) | (0, 180, 0) |  | text 'HERE', Comic Neue Bold, font_size 48, pixel_size 0.004, outline |
| Clock5 | `res://world/office/props/sets/wall_clock.tscn` | (3.5, 2.3, 7.875) | (0, 180, 0) |  | shows **6:52**; Label3D 'DEADLINE' 0.35 m below it |
| Label5 | `Label3D (built-in)` | (3.5, 1.95, 7.86) | (0, 180, 0) |  | text 'DEADLINE', Comic Neue Bold, font_size 48, pixel_size 0.004, outline |
| Bookshelf1 | `Bookshelf` | (-5.56, 0, -4) | (0, 90, 0) |  |  |
| Bookshelf2 | `Bookshelf` | (-5.56, 0, -5.2) | (0, 90, 0) |  |  |
| HighPainting | `Painting` | (-3, 3.1, -7.885) | (0, 0, 0) |  | **Paintings4 material (mountains)**, hung at 3.1 m: 'by someone very tall' |
| Cabinet1 | `FileCabinet_Standard` | (5.6, 0, -6.2) | (0, 270, 0) |  |  |
| Cabinet2 | `FileCabinet_Standard` | (5.6, 0, -5.6) | (0, 270, 0) |  |  |
| Cupboard | `Shelf_Base` | (5.6, 0, -4.5) | (0, 270, 0) |  |  |
| Vase2 | `Office_Deco` | (5.5, 0, -7.45) | (0, 0, 0) |  |  |
| LoungeTable | `CoffeeTable` | (4.2, 0, 5.2) | (0, 90, 0) |  |  |
| LoungeChair1 | `Chair_B` | (3.3, 0, 5.2) | (0, 90, 0) |  |  |
| LoungeChair2 | `Chair_B` | (5.15, 0, 5.2) | (0, 270, 0) |  |  |
| FruitPlate | `Fruit_Plate` | (4.2, 0.509, 5.2) | (0, 90, 0) |  |  |


≈259 nodes added in this room.


## B2: Employee of the Month (tier 2)

**Headline:** a giant (scale 8, 2 m tall) standing desk-photo frame `Painting_Small2` against the north wall under a sign "EMPLOYEE OF THE MONTH (EVERY MONTH)". **All 8 desks** have the same small `Painting_Small2` photo on them. Same face everywhere.

- 8 desks = 4 `desk_pair` prefabs (the 4 crosses on the sketch), one per quadrant. The full cross walkway between the 4 doors stays empty.
- Small gags: a 5-high stack of wooden chairs (each on the seat of the one below), bamboo growing out of a bin, a tower of moving boxes.
- Clock: 6:56.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |    EEE    ······    ss |   z=-8
  |    EEE    ······      @|
  |           ······       |
  |    DDD    ······  DDD  |
  |    DDD    ······  DDD  |   z=-4
  |    DDD    ······  DDD  |
  |           ······       |
  |           ······       |
  |························|   z=+0
  D························D
  |           ······       |
  |    DDD    ······  DDD  |
  |    DDD    ······  DDD  |   z=+4
  |    DDD    ······  DDD  |
  |    DDD    ······  DDD  |
  | t         ······     xx|
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `E` giant photo, `s` chair stack, `t` bin, `x` boxes.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| PairNW | `res://world/office/props/sets/desk_pair.tscn` | (-3.2, 0, -3.6) | (0, 0, 0) |  | add 2 children: `PhotoN` = Painting_Small2 at pair-local (0.45, 1.069, -0.125) rot Y 180 and `PhotoS` at (-0.45, 1.069, 0.125) rot Y 0: the same face on every desk |
| PairNE | `res://world/office/props/sets/desk_pair.tscn` | (4.2, 0, -3.6) | (0, 0, 0) |  | add 2 children: `PhotoN` = Painting_Small2 at pair-local (0.45, 1.069, -0.125) rot Y 180 and `PhotoS` at (-0.45, 1.069, 0.125) rot Y 0: the same face on every desk |
| PairSW | `res://world/office/props/sets/desk_pair.tscn` | (-3.2, 0, 5.2) | (0, 0, 0) |  | add 2 children: `PhotoN` = Painting_Small2 at pair-local (0.45, 1.069, -0.125) rot Y 180 and `PhotoS` at (-0.45, 1.069, 0.125) rot Y 0: the same face on every desk |
| PairSE | `res://world/office/props/sets/desk_pair.tscn` | (4.2, 0, 5.2) | (0, 0, 0) |  | add 2 children: `PhotoN` = Painting_Small2 at pair-local (0.45, 1.069, -0.125) rot Y 180 and `PhotoS` at (-0.45, 1.069, 0.125) rot Y 0: the same face on every desk |
| EmployeeOfTheMonth | `Painting_Small2` | (-3.2, 0.96, -7.3) | (0, 0, 0) | 8 | **uniform scale 8** (1.7 × 2.0 m standing frame); check the bottom touches the floor, adjust y |
| EOTMLabel | `Label3D (built-in)` | (-3.2, 2.75, -7.85) | (0, 0, 0) |  | 'EMPLOYEE OF THE MONTH' + newline + '(EVERY MONTH)', Comic Neue Bold |
| ChairStack1 | `Chair_A` | (5.2, 0, -7.2) | (0, 0, 0) |  | each sits on the seat of the one below |
| ChairStack2 | `Chair_A` | (5.2, 0.715, -7.2) | (0, 7, 0) |  |  |
| ChairStack3 | `Chair_A` | (5.2, 1.43, -7.2) | (0, -5, 0) |  |  |
| ChairStack4 | `Chair_A` | (5.2, 2.145, -7.2) | (0, 9, 0) |  |  |
| ChairStack5 | `Chair_A` | (5.2, 2.86, -7.2) | (0, -8, 0) |  |  |
| BambooBin | `TrashBin` | (-5.4, 0, 7.5) | (0, 0, 0) |  |  |
| Bamboo | `Nature_Deco_Bamboo1` | (-5.4, 0.15, 7.5) | (0, 30, 0) |  | growing out of the bin |
| Box1 | `Box_Base` | (5.3, 0, 7.3) | (0, 0, 0) |  |  |
| Box2 | `Box_Base` | (5.3, 0.65, 7.3) | (0, 12, 0) |  |  |
| Box3 | `Box_Base` | (5.3, 1.3, 7.3) | (0, -6, 0) |  |  |
| Clock | `res://world/office/props/sets/wall_clock.tscn` | (5.875, 2.4, -6.5) | (0, 270, 0) |  | shows **6:56** |


≈342 nodes added in this room.


## B1: Too many doors (tier 2)

**Headline:** a corridor of three free-standing door frames down the middle of the north half (doors open at different angles, all walkable). It leads to a fourth, closed door flush on the north wall that goes nowhere. Narrator: *"You could have walked around them. You didn't."*

- Use the new **openable door prop** for the three free-standing doors and the wall door if it works without a wall. Opening the last one reveals plain wall. With real doors at every doorway, this room is the joke about them.
- 4 desks = 2 `desk_pair`s in the south half (sketch: two crosses).
- Small gags: the lime **sports-car painting** (Paintings3) hung sideways as "motivation", a whiteboard installed facing the wall, the "side monitor" `Wall_TV`, bamboo in a trough.

```
  +------------------------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |P    w      ww          |   z=-8
  |P           ||          |
  |                        |
  |            ||          |
  |w                      w|   z=-4
  |            ||          |
  |                        |
  |                        |
  |························|   z=+0
  D························D
  |           ······       |
  |    DDD    ······  DDD  |
  |    DDD    ······  DDD  |   z=+4
  |    DDD    ······  DDD  |
  |    DDD    ······  DDD  |
  |           ······       |
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `|` free-standing door frame, `P` plant.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| PairSW | `res://world/office/props/sets/desk_pair.tscn` | (-3.2, 0, 5.2) | (0, 0, 0) |  |  |
| PairSE | `res://world/office/props/sets/desk_pair.tscn` | (4.2, 0, 5.2) | (0, 0, 0) |  |  |
| DoorFrame1 | `Door_Frame` | (0.43, 0, -2.6) | (0, 0, 0) |  | free-standing, opening centred on x = 1 (pivot = left edge, spans x 0.43 → 1.57) |
| Door1 | `Door_B` | (0.515, 0, -2.6) | (0, 70, 0) |  | hinged on the frame's left post, open 70°; walkable |
| DoorFrame2 | `Door_Frame` | (0.43, 0, -4.4) | (0, 0, 0) |  | free-standing, opening centred on x = 1 (pivot = left edge, spans x 0.43 → 1.57) |
| Door2 | `Door_C` | (0.515, 0, -4.4) | (0, 35, 0) |  | hinged on the frame's left post, open 35°; walkable |
| DoorFrame3 | `Door_Frame` | (0.43, 0, -6.2) | (0, 0, 0) |  | free-standing, opening centred on x = 1 (pivot = left edge, spans x 0.43 → 1.57) |
| Door3 | `Door_A` | (0.515, 0, -6.2) | (0, 100, 0) |  | hinged on the frame's left post, open 100°; walkable |
| LastDoorFrame | `Door_Frame` | (0.43, 0, -7.775) | (0, 0, 0) |  | flush on the north wall: the corridor of doors ends in a closed door to nowhere |
| LastDoor | `Door_A` | (0.515, 0, -7.855) | (0, 0, 0) |  | closed |
| Lamborghini | `Painting` | (-5.885, 1.8, -4) | (0, 90, 90) |  | **Paintings3 material (lime sports car)**, turned 90° (portrait): 'motivational' |
| SideTV | `Wall_TV` | (5.88, 1.8, -4) | (0, 270, 0) |  | the 'side monitor' (subway-surfers idea); optional emissive screen |
| BackwardsWhiteboard | `WhiteBoard_Big` | (-3.5, 1.5, -7.82) | (0, 180, 0) |  | **rot Y 180 instead of 0**: installed facing the wall |
| Trough | `Nature_Deco` | (-5.6, 0, -6.8) | (0, 0, 0) |  |  |
| BambooA | `Nature_Deco_Bamboo1` | (-5.6, 0.3, -7.1) | (0, 0, 0) |  | standing in the trough |
| BambooB | `Nature_Deco_Bamboo2` | (-5.6, 0.3, -6.5) | (0, 140, 0) |  |  |


≈198 nodes added in this room.


## B3: Forced perspective (tier 2)

**Headline:** four desks in a row along the south wall, each smaller than the last (scale 1.0, 0.82, 0.66, 0.5), seen from the west door like perspective that lies. The *fifth* desk is a scale-0.15 dollhouse workstation standing on the first desk.

- The shrinking desks use wooden `Chair_A` scaled with them, because the office-chair prop is a RigidBody and can't be scaled. This is the one exception to "office chairs everywhere".
- Small gags: a filing-cabinet tower 3 high with drawers pulled out in a staircase, a giant coffee mug (scale 7) used as a planter, five small frames climbing the wall like a staircase.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |  www ww   ······       |   z=-8
  |           ······       |
  |           ······       |
  |f          ······  MMM  |
  |f          ······       |   z=-4
  |           ······       |
  |           ······       |
  |           ······       |
  |························|   z=+0
  D························D
  |                        |
  |                        |
  |  aa  aa                |   z=+4
  |  DDDDaa aaDa           |
  |                        |
  |                        |
  +------------------------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `a` wooden chair, `f` file cabinet, `M` giant mug.

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| ShrinkDesk1 | `res://world/office/props/sets/ws_modern.tscn` | (-4.4, 0, 5.6) | (0, 180, 0) |  | full size |
| ShrinkChair1 | `Chair_A` | (-4.4, 0, 4.85) | (0, 0, 0) |  | wooden chair (props can't scale), scale 1.00 |
| ShrinkDesk2 | `res://world/office/props/sets/ws_modern.tscn` | (-2.55, 0, 5.6) | (0, 180, 0) | 0.82 | **uniform scale 0.82** |
| ShrinkChair2 | `Chair_A` | (-2.55, 0, 4.985) | (0, 0, 0) | 0.82 | wooden chair (props can't scale), scale 0.82 |
| ShrinkDesk3 | `res://world/office/props/sets/ws_modern.tscn` | (-1.05, 0, 5.6) | (0, 180, 0) | 0.66 | **uniform scale 0.66** |
| ShrinkChair3 | `Chair_A` | (-1.05, 0, 5.105) | (0, 0, 0) | 0.66 | wooden chair (props can't scale), scale 0.66 |
| ShrinkDesk4 | `res://world/office/props/sets/ws_modern.tscn` | (0.14, 0, 5.6) | (0, 180, 0) | 0.5 | **uniform scale 0.50** |
| ShrinkChair4 | `Chair_A` | (0.14, 0, 5.225) | (0, 0, 0) | 0.5 | wooden chair (props can't scale), scale 0.50 |
| DollhouseDesk | `res://world/office/props/sets/ws_modern.tscn` | (-3.95, 0.949, 5.5) | (0, 180, 0) | 0.15 | **scale 0.15** workstation standing on ShrinkDesk1's top: the 5th, smallest desk |
| FileTower1 | `FileCabinet_Standard` | (-5.62, 0, -4) | (0, 90, 0) |  | stacked 3 high (top at 3.15 m) |
| FileTowerDrawer1 | `FileCabinet_Standard_Drawer` | (-5.17, 0.7, -4) | (0, 90, 0) |  | top drawer pulled out 0.45 m (staircase); tune y/x by eye |
| FileTower2 | `FileCabinet_Standard` | (-5.62, 1.05, -4) | (0, 90, 0) |  |  |
| FileTowerDrawer2 | `FileCabinet_Standard_Drawer` | (-4.97, 1.75, -4) | (0, 90, 0) |  | top drawer pulled out 0.65 m (staircase); tune y/x by eye |
| FileTower3 | `FileCabinet_Standard` | (-5.62, 2.1, -4) | (0, 90, 0) |  |  |
| FileTowerDrawer3 | `FileCabinet_Standard_Drawer` | (-4.77, 2.8, -4) | (0, 90, 0) |  | top drawer pulled out 0.85 m (staircase); tune y/x by eye |
| GiantMug | `CoffeeCup` | (4.3, 0, -4.5) | (0, 200, 0) | 7 | **uniform scale 7** (≈0.85 m tall planter) |
| GiantMugPlant | `Nature_Deco_3` | (4.3, 0.55, -4.5) | (0, 0, 0) | 1.1 | sunk into the mug |
| StairPainting1 | `Painting_Small` | (-5, 1.2, -7.88) | (0, 0, 0) |  | climbing staircase of frames |
| StairPainting2 | `Painting_Small` | (-4.3, 1.5, -7.88) | (0, 0, 0) |  |  |
| StairPainting3 | `Painting_Small` | (-3.6, 1.8, -7.88) | (0, 0, 0) |  |  |
| StairPainting4 | `Painting_Small` | (-2.9, 2.1, -7.88) | (0, 0, 0) |  |  |
| StairPainting5 | `Painting_Small` | (-2.2, 2.4, -7.88) | (0, 0, 0) |  |  |


≈193 nodes added in this room.


## C2: The upside-down room (tier 3)

**Headline: the entire room is on the ceiling.** The 4-desk pinwheel (sketch cluster), its four chairs (**all frozen**), floor lamps, plants, cabinets, a coffee counter with its coffee machine and mug, a bin. Paintings, the whiteboard and the clock are mounted upside down, and the clock runs backwards. The only thing on the floor is one ordinary, upright, pushable chair. Narrator: *"One of them didn't get the memo. Don't be like that chair."*

- **How:** every ceiling item has its origin at y = 3.875 and rotation (0, Y, **180**), i.e. flipped around Z. The pinwheel is one `CeilingPinwheel` Node3D at (2, 3.875, 0) rot (0, 0, 180) whose children are a normal pinwheel (same numbers as A1).
- Lowest hanging points: Lamp_1 bottoms at 2.36 m, CoffeeMachine at 2.29 m. Everything else is higher. Player capsule is 1.75 m, so nothing is at head height. Nothing taller than 1.55 m goes on the ceiling (no bookshelves).
- Checked that nothing on the ceiling covers a light panel (lights at x −4/0/4, z −6/−2/2/6).
- Walls: upside-down paintings are rotated around their own facing axis, so their fronts still face the room (no backface problems). No single-sided models (rugs, document sheets, box flaps, fan blades, AirConditioner_B) are used here.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  | pp   w    ······       |   z=-8
  |           ······       |
  |        l  ·····l       |
  |           ······     qq|
  |           ······     qq|   z=-4
  |@          ······       |
  |uu         ····h·       |
  |           ···ddddh     |
  |·············hdddd      |   z=+0
  D················h       |
  |           ······       |
  |kk         ······       |
  |kk    c    ······       |   z=+4
  |           ······       |
  |        l  ·····l       |
  |      w    ······    pp |
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `d` desk / desk pair (on the ceiling), `h` office chair (prop) (on the ceiling), `l` floor lamp (on the ceiling), `q` file cabinet (on the ceiling), `k` counter (on the ceiling), `p` plant (on the ceiling), `u` bin (on the ceiling), `c` office chair (prop).

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| **CeilingPinwheel** (Node3D group) | – | (2, 3.875, 0) | (0, 0, 180) | | rotation (0, 0, 180): the whole pinwheel hangs from the ceiling; children = normal pinwheel. Rows marked ↳ are children in group-local coords |
| ↳ Desk1 | `res://world/office/props/sets/ws_modern.tscn` | (0.375, 0, -0.74) | (0, 180, 0) |  |  |
| ↳ Desk1Chair | `res://world/office/props/office_chair.tscn` | (0.375, 0, -1.49) | (0, 0, 0) |  | model Executive; **freeze = true** |
| ↳ Desk2 | `res://world/office/props/sets/ws_modern.tscn` | (0.74, 0, 0.375) | (0, 90, 0) |  |  |
| ↳ Desk2Chair | `res://world/office/props/office_chair.tscn` | (1.49, 0, 0.375) | (0, 270, 0) |  | model Armchair; **freeze = true** |
| ↳ Desk3 | `res://world/office/props/sets/ws_modern.tscn` | (-0.375, 0, 0.74) | (0, 0, 0) |  |  |
| ↳ Desk3Chair | `res://world/office/props/office_chair.tscn` | (-0.375, 0, 1.49) | (0, 180, 0) |  | model Task; **freeze = true** |
| ↳ Desk4 | `res://world/office/props/sets/ws_modern.tscn` | (-0.74, 0, -0.375) | (0, 270, 0) |  |  |
| ↳ Desk4Chair | `res://world/office/props/office_chair.tscn` | (-1.49, 0, -0.375) | (0, 90, 0) |  | model Armchair; **freeze = true** |
| ↳ HangingVase | `Nature_Deco_2` | (0, 0, 0) | (0, 0, 0) |  | pinwheel hole |
| ↳ HangingPhoto | `Painting_Small2` | (0.825, 1.069, -0.49) | (0, 180, 0) |  | desk photo on Desk1 (group-local, desk-top height) |
| CeilingLamp1 | `Lamp_1` | (-2, 3.875, -6) | (0, 0, 180) |  | floor lamp hanging upside down (bottom at 2.36 m) |
| CeilingLamp2 | `Lamp_1` | (-2, 3.875, 6) | (0, 0, 180) |  | floor lamp hanging upside down (bottom at 2.36 m) |
| CeilingLamp3 | `Lamp_1` | (2, 3.875, -6) | (0, 0, 180) |  | floor lamp hanging upside down (bottom at 2.36 m) |
| CeilingLamp4 | `Lamp_1` | (2, 3.875, 6) | (0, 0, 180) |  | floor lamp hanging upside down (bottom at 2.36 m) |
| CeilingCabinet1 | `FileCabinet_Standard` | (5.6, 3.875, -4) | (0, 270, 180) |  |  |
| CeilingCabinet2 | `FileCabinet_Standard` | (5.6, 3.875, -3.4) | (0, 270, 180) |  |  |
| CeilingCounter | `Office_CounterA1` | (-5.55, 3.875, 4) | (0, 90, 180) |  |  |
| CeilingCoffee | `CoffeeMachine` | (-5.6, 2.926, 4) | (0, 90, 180) |  | hangs under the counter top (bottom at 2.29 m) |
| CeilingMug | `CoffeeCup_Filled` | (-5.55, 2.926, 3.4) | (0, 90, 180) |  | the coffee doesn't spill (opaque swatch) |
| CeilingPlant1 | `Nature_Deco_3` | (-5.2, 3.875, -7.2) | (0, 0, 180) |  |  |
| CeilingPlant2 | `Nature_Deco_3` | (5.2, 3.875, 7.2) | (0, 0, 180) |  |  |
| CeilingBin | `TrashBin` | (-5.5, 3.875, -1.5) | (0, 0, 180) |  |  |
| UpsideDownPainting | `Painting` | (-3, 2, -7.885) | (0, 0, 180) |  | **Paintings2 material** (blue abstract) |
| UpsideDownWhiteboard | `WhiteBoard_Big` | (-3, 2.2, 7.82) | (0, 180, 180) |  |  |
| UpsideDownClock | `res://world/office/props/sets/wall_clock.tscn` | (-5.875, 2.6, -3) | (0, 90, 180) |  | shows **6:55**; runs **backwards** (wall_clock `minutes_per_second = -1`) |
| TheOneThatDidntGetTheMemo | `res://world/office/props/office_chair.tscn` | (-3, 0, 4.5) | (0, 35, 0) |  | model Task, **the only floor item**, upright and pushable (narrator: 'didn't get the memo') |


≈228 nodes added in this room.


## C3: The meeting (tier 3)

**Headline:** at the end of the walkway from the west door, five office chairs sit in a circle around a round table, facing a potted plant that is "chairing" the meeting, with a projector pointed at it. Narrator: *"The 7 pm sync. Mandatory. You weren't invited."*

- 8 desks = 4 `desk_pair`s (the 4 crosses on the sketch), each **rotated 15° more than the last** (0°, 15°, 30°, 45°): the room is slowly twisting.
- Small gags: four paintings on the north wall, each rotated 15° further around Z. Dinner (a stacked sandwich) on a keyboard. A low wall of briefcases.
- C3 is the dead-end corner (doors west and north only), so the south half is free for the rotated pods.

```
  +-------------DD---------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |  w w w w  ······       |   z=-8
  |           ······       |
  |    DDD    ······ DDDDD |
  |    DDD    ······ DDDDD |
  |    DDD    ······ DDDDD |   z=-4
  |    DDD    ······ DDDDD |
  |           ······       |
  |           ······    c  |
  |················· c TT  |   z=+0
  D················· c TTc |
  |                     c  |
  |  DDDDDDD      DDDDDD   |
  |  DDDDDDD      DDDDDD   |   z=+4
  |  DDDDDDD      DDDDDD   |
  |  DDDDDDD      DDDDDD   |
  |                        |
  +------------------------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `D` desk / desk pair, `T` table, `c` office chair (prop).

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| PairNW | `res://world/office/props/sets/desk_pair.tscn` | (-3.2, 0, -4.2) | (0, 0, 0) |  | rot 0°: each pod twisted 15° more than the last |
| PairNE | `res://world/office/props/sets/desk_pair.tscn` | (4.2, 0, -4.2) | (0, 15, 0) |  | rot 15°: each pod twisted 15° more than the last |
| PairSE | `res://world/office/props/sets/desk_pair.tscn` | (3, 0, 5.2) | (0, 30, 0) |  | rot 30°: each pod twisted 15° more than the last |
| PairSW | `res://world/office/props/sets/desk_pair.tscn` | (-3.2, 0, 5.2) | (0, 45, 0) |  | rot 45°: each pod twisted 15° more than the last |
| MeetingTable | `Table_Circular` | (4.3, 0, 1) | (0, 0, 0) |  | at the end of the walkway from the west door |
| MeetingChairPlant | `Nature_Deco_3` | (4.3, 0.949, 1) | (0, 0, 0) | 0.8 | the plant is chairing the meeting |
| MeetingChair1 | `res://world/office/props/office_chair.tscn` | (5.45, 0, 1) | (0, 270, 0) |  | faces the plant; model Executive; pushable |
| MeetingChair2 | `res://world/office/props/office_chair.tscn` | (4.66, 0, -0.09) | (0, 342, 0) |  | faces the plant; model Armchair; pushable |
| MeetingChair3 | `res://world/office/props/office_chair.tscn` | (3.37, 0, 0.32) | (0, 54, 0) |  | faces the plant; model Task; pushable |
| MeetingChair4 | `res://world/office/props/office_chair.tscn` | (3.37, 0, 1.68) | (0, 126, 0) |  | faces the plant; model Armchair; pushable |
| MeetingChair5 | `res://world/office/props/office_chair.tscn` | (4.66, 0, 2.09) | (0, 198, 0) |  | faces the plant; model Task; pushable |
| MeetingProjector | `Projector` | (4.55, 0.949, 0.8) | (0, 270, 0) |  | pointed at the plant |
| TwistPainting1 | `Painting` | (-5, 1.8, -7.885) | (0, 0, 0) |  | **Paintings2 material**; rot Z 0°: the painting slowly twisting |
| TwistPainting2 | `Painting` | (-3.9, 1.8, -7.885) | (0, 0, -15) |  | **Paintings2 material**; rot Z -15°: the painting slowly twisting |
| TwistPainting3 | `Painting` | (-2.8, 1.8, -7.885) | (0, 0, -30) |  | **Paintings2 material**; rot Z -30°: the painting slowly twisting |
| TwistPainting4 | `Painting` | (-1.7, 1.8, -7.885) | (0, 0, -45) |  | **Paintings2 material**; rot Z -45°: the painting slowly twisting |
| Sandwich | `Food_Bread` | (-3.2, 0.99, -3.705) | (0, 0, 0) |  | on PairNW's south keyboard; stack Food_CheeseSlice (y +0.02), Food_LettuceSlice (+0.035), Food_TomatoSlice (+0.05), Food_Bread (+0.06): dinner at the desk |
| BriefcaseWall1 | `Briefcase_1` | (-5.75, 0, -7.2) | (0, 90, 0) |  | briefcases stacked like bricks, 2 wide × 2 high, against the west wall |
| BriefcaseWall2 | `Briefcase_1` | (-5.75, 0, -6.45) | (0, 90, 0) |  |  |
| BriefcaseWall3 | `Briefcase_1` | (-5.75, 0.61, -7.2) | (0, 90, 0) |  |  |
| BriefcaseWall4 | `Briefcase_1` | (-5.75, 0.61, -6.45) | (0, 90, 0) |  |  |


≈382 nodes added in this room.


## C1: Server room ("Gen") (tier 4)

**Headline:** "mainframes" that are just giant PC cases (`Computer_Case` at scale (3.2, 4.6, 2.6)) in two tidy rows lining an aisle that runs from the west door straight to the **reserved switchboard spot on the east wall**. The last rack before the switchboard is the beige **legacy mainframe** (`Computer_Case_Old`), with a framed photo on top ("in loving memory") and a sticky note. Back wall: shelves of real-size PCs and a 5 × 3 wall of stacked towers. Narrator: *"We couldn't afford servers, so we bought very large computers."*

- **Doors:** the west doorway (B1) and south doorway (C2) get the new openable doors. The nearest racks are 2.3 m from each doorway centre, so both leaves can swing freely.
- **Switchboard spot:** `SwitchboardSpot` Marker3D at (5.85, 0, 1.0) rot Y 270 (faces west). Keep x 3.4…5.9, z −0.6…2.6 empty. You see it from the west doorway straight down the 3 m aisle, and the south door joins the aisle through the gap in the south row.
- Racks: 0.62 m on centres. North row (12, incl. legacy) fronts face +Z. South row (6 + 4, gap for the south door's walkway) fronts face −Z.
- Cooling "solution": three desk fans on the floor behind the north row, plus an AC unit.
- Monitoring station: Office_Desk_3 with a 3 × 2 wall of CRTs and an executive chair.
- Clock 6:54 above the switchboard spot. Sign: "SERVER ROOM (budget edition)".
- **Lights: amber, with a flicker.** Recolour **all 12** `Rooms/C1/Lights/CeilingLight1…12` to amber: SpotLight3D `light_color` = (1.0, 0.70, 0.32), `light_energy` 3.0 (instead of 3.5). Give their `Panel` a new material `world/office/materials/ceiling_light_panel_amber.tres` (copy of `ceiling_light_panel.tres` with an amber emission) as `material_override`, via Editable Children. Don't edit the shared panel material. I chose **amber/yellow over blue**: the whole office is already lit cold blue (0.77, 0.85, 1.0), so a blue server room wouldn't stand out. Amber reads as "emergency / generator power" (the sketch calls the room "Gen"), shows from the doorways, and tells the player that the light trouble starts here.
- **Flicker:** only **CeilingLight6** (x 4, z −2, over the legacy mainframe and the aisle's end) and **CeilingLight9** (x 4, z 2, over the switchboard approach). Add a small `world/office/parts/light_flicker.gd` on those two instances. It works on `light_energy` (and the panel's emission energy): mostly steady, every 2–6 s (random) a burst of 2–5 quick drops to 0–30% for 0.05–0.15 s each. Optionally play a quiet electrical buzz/tick from the 400 Sounds pack on an `AudioStreamPlayer3D`. It must keep running while paused (or deliberately stop; pick one), and it should expose `enabled` so the story can make it stop or go fully dark later. Only 2 of the 12 lights flicker, so the switchboard stays readable.

```
  +------------------------+   N (-z) up, x right; 1 col = 0.5 m, 1 row = 1 m
  |  ppppppp         ppp   |   z=-8
  |                        |
  |                        |
  |                        |
  |                        |   z=-4
  |      F    F   F        |
  |   RRRRRRRRRRRRRGG      |
  |                   ·····|
  |························|   z=+0
  D·······················@|
  |           ······  ·····|
  |   RRRRRRRR······RRRRRR |
  |           ······       |   z=+4
  |           ······       |
  |    c      ······       |
  |  DDDDD    ······       |
  +-------------DD---------+
   x=-6        0          6
```

Legend: `·` keep-clear walkway, `D` on the border = doorway, `w` wall item (painting/board/TV/sign), `@` wall clock, `R` server rack, `G` legacy mainframe, `p` PC stacks, `F` floor fan, `D` desk / desk pair, `c` office chair (prop).

| Node | Model / scene | Pos (x, y, z) | Rot (X, Y, Z)° | Scale | Notes |
|---|---|---|---|---|---|
| RackN1 | `res://world/office/props/sets/server_rack.tscn` | (-4.2, 0, -1.3) | (0, 0, 0) |  | north row, fronts face the aisle |
| RackN2 | `res://world/office/props/sets/server_rack.tscn` | (-3.58, 0, -1.3) | (0, 0, 0) |  |  |
| RackN3 | `res://world/office/props/sets/server_rack.tscn` | (-2.96, 0, -1.3) | (0, 0, 0) |  |  |
| RackN4 | `res://world/office/props/sets/server_rack.tscn` | (-2.34, 0, -1.3) | (0, 0, 0) |  |  |
| RackN5 | `res://world/office/props/sets/server_rack.tscn` | (-1.72, 0, -1.3) | (0, 0, 0) |  |  |
| RackN6 | `res://world/office/props/sets/server_rack.tscn` | (-1.1, 0, -1.3) | (0, 0, 0) |  |  |
| RackN7 | `res://world/office/props/sets/server_rack.tscn` | (-0.48, 0, -1.3) | (0, 0, 0) |  |  |
| RackN8 | `res://world/office/props/sets/server_rack.tscn` | (0.14, 0, -1.3) | (0, 0, 0) |  |  |
| RackN9 | `res://world/office/props/sets/server_rack.tscn` | (0.76, 0, -1.3) | (0, 0, 0) |  |  |
| RackN10 | `res://world/office/props/sets/server_rack.tscn` | (1.38, 0, -1.3) | (0, 0, 0) |  |  |
| RackN11 | `res://world/office/props/sets/server_rack.tscn` | (2, 0, -1.3) | (0, 0, 0) |  |  |
| RackN12 | `res://world/office/props/sets/server_rack_legacy.tscn` | (2.62, 0, -1.3) | (0, 0, 0) |  | **LEGACY MAINFRAME** (beige) |
| RackS1 | `res://world/office/props/sets/server_rack.tscn` | (-4.2, 0, 3.3) | (0, 180, 0) |  | south row, fronts face the aisle |
| RackS2 | `res://world/office/props/sets/server_rack.tscn` | (-3.58, 0, 3.3) | (0, 180, 0) |  |  |
| RackS3 | `res://world/office/props/sets/server_rack.tscn` | (-2.96, 0, 3.3) | (0, 180, 0) |  |  |
| RackS4 | `res://world/office/props/sets/server_rack.tscn` | (-2.34, 0, 3.3) | (0, 180, 0) |  |  |
| RackS5 | `res://world/office/props/sets/server_rack.tscn` | (-1.72, 0, 3.3) | (0, 180, 0) |  |  |
| RackS6 | `res://world/office/props/sets/server_rack.tscn` | (-1.1, 0, 3.3) | (0, 180, 0) |  |  |
| RackS7 | `res://world/office/props/sets/server_rack.tscn` | (3.1, 0, 3.3) | (0, 180, 0) |  |  |
| RackS8 | `res://world/office/props/sets/server_rack.tscn` | (3.72, 0, 3.3) | (0, 180, 0) |  |  |
| RackS9 | `res://world/office/props/sets/server_rack.tscn` | (4.34, 0, 3.3) | (0, 180, 0) |  |  |
| RackS10 | `res://world/office/props/sets/server_rack.tscn` | (4.96, 0, 3.3) | (0, 180, 0) |  |  |
| LegacyPhoto | `Painting_Small2` | (2.62, 1.96, -1.35) | (0, 0, 0) |  | standing on top of the legacy mainframe: 'in loving memory' |
| LegacySticky | `StickNote_1` | (2.62, 1.2, -0.81) | (90, 0, 0) |  | stuck on its front (rot X 90 so it faces +Z; flip if invisible) |
| SwitchboardSpot | `Marker3D (built-in)` | (5.85, 0, 1) | (0, 270, 0) |  | **reserved**: switchboard goes on the east wall here, facing west; keep x 3.4…5.9, z −0.6…2.6 empty |
| PCStack1 | `res://world/office/props/sets/pc_shelf_stack.tscn` | (-4.6, 0, -7.65) | (0, 0, 0) |  |  |
| PCStack2 | `res://world/office/props/sets/pc_shelf_stack.tscn` | (-3.8, 0, -7.65) | (0, 0, 0) |  |  |
| PCStack3 | `res://world/office/props/sets/pc_shelf_stack.tscn` | (-3, 0, -7.65) | (0, 0, 0) |  |  |
| PCStack4 | `res://world/office/props/sets/pc_shelf_stack.tscn` | (-2.2, 0, -7.65) | (0, 0, 0) |  |  |
| PCWall_1_1 | `Computer_Case` | (3.2, 0, -7.6) | (0, 0, 0) |  | 5 columns × 3 high of real-size towers |
| PCWall_1_2 | `Computer_Case` | (3.2, 0.41, -7.6) | (0, 0, 0) |  |  |
| PCWall_1_3 | `Computer_Case` | (3.2, 0.82, -7.6) | (0, 0, 0) |  |  |
| PCWall_2_1 | `Computer_Case` | (3.4, 0, -7.6) | (0, 0, 0) |  |  |
| PCWall_2_2 | `Computer_Case` | (3.4, 0.41, -7.6) | (0, 0, 0) |  |  |
| PCWall_2_3 | `Computer_Case` | (3.4, 0.82, -7.6) | (0, 0, 0) |  |  |
| PCWall_3_1 | `Computer_Case` | (3.6, 0, -7.6) | (0, 0, 0) |  |  |
| PCWall_3_2 | `Computer_Case` | (3.6, 0.41, -7.6) | (0, 0, 0) |  |  |
| PCWall_3_3 | `Computer_Case` | (3.6, 0.82, -7.6) | (0, 0, 0) |  |  |
| PCWall_4_1 | `Computer_Case` | (3.8, 0, -7.6) | (0, 0, 0) |  |  |
| PCWall_4_2 | `Computer_Case` | (3.8, 0.41, -7.6) | (0, 0, 0) |  |  |
| PCWall_4_3 | `Computer_Case` | (3.8, 0.82, -7.6) | (0, 0, 0) |  |  |
| PCWall_5_1 | `Computer_Case` | (4, 0, -7.6) | (0, 0, 0) |  |  |
| PCWall_5_2 | `Computer_Case` | (4, 0.41, -7.6) | (0, 0, 0) |  |  |
| PCWall_5_3 | `Computer_Case` | (4, 0.82, -7.6) | (0, 0, 0) |  |  |
| AirCon | `AirConditioner_A` | (-3.4, 3.2, -7.72) | (0, 0, 0) |  |  |
| CoolingFan1 | `Small_Fan` | (-3, 0, -2.45) | (0, 0, 0) |  | desk fan on the floor 'cooling' the racks |
| CoolingFan2 | `Small_Fan` | (-0.5, 0, -2.45) | (0, 0, 0) |  |  |
| CoolingFan3 | `Small_Fan` | (1.8, 0, -2.45) | (0, 0, 0) |  |  |
| ControlDesk | `Office_Desk_3` | (-3.6, 0, 7.45) | (0, 180, 0) |  | monitoring station |
| CRT_1_1 | `Computer_Old_Monitor` | (-2.9, 0.949, 7.55) | (0, 180, 0) |  | CRT wall, 3 wide × 2 high |
| CRT_1_2 | `Computer_Old_Monitor` | (-2.9, 1.459, 7.55) | (0, 180, 0) |  |  |
| CRT_2_1 | `Computer_Old_Monitor` | (-3.6, 0.949, 7.55) | (0, 180, 0) |  |  |
| CRT_2_2 | `Computer_Old_Monitor` | (-3.6, 1.459, 7.55) | (0, 180, 0) |  |  |
| CRT_3_1 | `Computer_Old_Monitor` | (-4.3, 0.949, 7.55) | (0, 180, 0) |  |  |
| CRT_3_2 | `Computer_Old_Monitor` | (-4.3, 1.459, 7.55) | (0, 180, 0) |  |  |
| ControlChair | `res://world/office/props/office_chair.tscn` | (-3.6, 0, 6.7) | (0, 0, 0) |  | model Executive |
| Clock | `res://world/office/props/sets/wall_clock.tscn` | (5.875, 2.9, 1) | (0, 270, 0) |  | shows **6:54**; above the switchboard spot |
| Sign | `Label3D (built-in)` | (-4, 2.6, -7.86) | (0, 0, 0) |  | 'SERVER ROOM' + newline + '(budget edition)' |


≈303 nodes added in this room.


## Implementation notes

**Order of work.** (1) Create the prefabs and painting materials. (2) Delete `OfficeChair2`/`OfficeChair3` in Start. (3) Furnish one room at a time under `Rooms/<Room>/Furniture`, saving after each. If people work in parallel, use README's "Save Branch as Scene" per room. (4) Run the checks below.

**Recipes used.**
- `ws_modern` single desk + its own chair: A2 (2), B3 (scaled ×4).
- Pinwheel of 4 (`ws_modern` ×4, chairs, vase in the 0.73 m hole): A1, A3 (mirrored, one `ws_retro`), C2 (on the ceiling). Group-local, normal version: desks at (0.375, 0, −0.74) rot 180, (0.74, 0, 0.375) rot 90, (−0.375, 0, 0.74) rot 0, (−0.74, 0, −0.375) rot 270. Each chair sits at the desk + 0.75 m along its knee direction, rot = desk + 180. Mirrored: negate x and swap 90 ↔ 270. Footprint ≈ 3.7 × 3.7 m.
- `desk_pair`: B2 (4), B1 (2), C3 (4, rotated 0/15/30/45).
- Racks: C1 only (21 + 1 legacy).

**Collision rules.**
- Every FBX instance brings its own static trimesh body. That's fine for **uniform** scales (giant mug ×7, giant photo ×8, shrinking desks, the ×0.15 dollhouse) and for upside-down items.
- **Non-uniform scale only in the racks**, which use their own BoxShape3D (see `server_rack.tscn`). Expect no "non-uniform scale" warnings anywhere else. If one appears, something got scaled by mistake.
- Never put a static FBX inside a chair (RigidBody). The plant on Fern's chair, the ceiling chairs' surroundings and so on are siblings, not children.
- Stacks (chair stack, boxes, file tower, PC wall) are separate static bodies resting on each other. They are not RigidBodies, so nothing settles or falls.
- Tiny clutter keeps its auto bodies (harmless for the 0.3 m capsule; the interact ray only hits layer 2).

**Frozen chairs (set `freeze = true` on the instance).** A1 Fern's chair (Desk3's chair in the pinwheel). C2: all four ceiling chairs. That's all: 5 of the 43 office chairs (23 placed directly + 20 inside the 10 `desk_pair`s). The other 38 stay pushable. Frozen chairs make no sound (the roll sound follows velocity).

**Upside-down rules (C2).** Origin y = 3.875, rot (0, θ, 180). Groups: put rot (0, 0, 180) on the group and keep the children's normal values. Items may hang down to 2.25 m at most (the lowest here are 2.29 / 2.36 m). Avoid the light panels (1 × 1 m at x −4/0/4, z −6/−2/2/6); the plan already does. Skip single-sided models on the ceiling (Rug_A/B, Office_Files_D_Custom, Box_A/B, Small_Fan_Acc, AirConditioner_B), or give them a `cull_mode = disabled` override.

**Performance.** About 2,300 new nodes (desk prefab ≈ 25 nodes, chair ≈ 10, rack 3). In total: 43 desks, 43 office chairs, 22 racks. That's fine for this map (it ran at about 1,000 fps with ~360 draw calls). If FPS or draw calls get bad:
1. Set `visibility_range_end` = 14 m (with a 2 m fade margin) on the small meshes inside `ws_modern`/`ws_retro` (mouse, keyboard, mug, PC case, phone). One edit covers every desk.
2. Drop `Computer_Mouse` and `Computer_Case` from `ws_modern`.
3. Bake an `OccluderInstance3D` for the walls (CPU occlusion culling also works in the Compatibility renderer).
No new lights are added (C1 only recolours its existing 12 and flickers 2), so the 16-lights-per-object limit isn't affected.

**Doors.** The door prop (built by another agent) goes into all 13 doorways first, so furnishing can be checked with the doors in place. The plan keeps a 1.5 m radius around every doorway centre clear on both sides. Re-check this if the door prop's leaf is wider than 1.0 m or opens past 90°. Ceiling items in C2 hang no lower than 2.29 m, above the 2.02 m door height.

**How to verify.**
1. Open `office.tscn`, top-down orthographic view of each room. Compare against the ASCII sketch; check that nothing pokes through a wall and the walkways are empty.
2. Play: open every door (X) from both sides and check that the leaf hits nothing; walk every doorway → doorway route (13 doorways) without snagging; push one chair in each room. In C2, look up: no chair falls (frozen) and nothing hides a light panel. Walk under the C2 ceiling lamps (no head bump).
3. Output panel: no "non-uniform scale" warnings, no missing-resource errors.
4. Check the visuals that rely on guesses: painting fronts (rot 180 if you see the back), `Painting_Small2` resting on its base, the giant photo's y (bottom on the floor), the `Door_Frame`/`Door_*` pivots (snap with snappy), the file-tower drawer offsets, the clock face direction, the shelf open face.
5. Uncapped FPS (Debug → Monitors) standing in B2's doorway looking into C2, compared with before.

## Open questions

1. **Start:** I removed both test chairs (`OfficeChair2`, `OfficeChair3`) and put the pushable "toy" chair in A2. The Start clock is marked optional. OK?
2. **`Painting_Small2` shows a real-looking person** (boy in a cap; the alternatives on Paintings3/4 are a girl and a woman). B2 uses it 9 times (8 desk photos + the giant one), plus one each in C1 and C2. Keep it, or swap in a custom (e.g. Comic Sans "your face here") texture?
3. **Switchboard spot:** east wall of C1 at (5.85, 0, 1), facing west, at the end of the server aisle. Is that the right wall? The second and third visits (switchboard moved, yellow bricks, sphinx) are not planned here.
4. **C2 floor gag:** one upright pushable chair ("didn't get the memo"). Alternative or extra: move one of C2's existing `CeilingLight`s to the floor, flipped to shine up (same light count). Want it?
5. **Clock countdown** (6:59 → 6:54 moving away from Start) as a loop/rewind seed for the narrator. Keep it, or show the same time everywhere?
6. **B3 shrinking row** uses wooden `Chair_A`, because RigidBody chairs can't scale. Is that OK as the one exception to "office chairs everywhere"?
7. **Lamp forest** (a grid of 10–15 floor lamps, one lit) was cut for space. It's very on-theme ("light is the antagonist"). It could replace C3's meeting, or go in the empty north half of B1 instead of the door corridor.
8. **Prefab folder** `world/office/props/sets/` and the new `wall_clock.gd` script: OK?
9. **Label3D signs** (A3 time zones, B2 Employee of the Month, C1 sign): OK, or should signage wait for proper textures?
10. **C1 light colour:** amber proposed (see C1). Switch to blue? Should the flicker run all the time, or only after a story beat (e.g. the first blackout)?
11. Should A2's fake door and B1's free-standing doors use the new **openable door prop** (open onto a wall), or stay as static models?
12. Node budget (~2,300) acceptable, or trim the desk recipe now (option 2 above)?

## As built (part 1)

Prefabs, materials and the first seven rooms are in. Screenshots: `screenshots/<room>.png` (from a doorway) and `screenshots/<room>_top.png` (top-down, ceiling hidden, **north is on the left, east at the top**). Deviations from the tables above:

**Prefabs**
- Extra prefabs: `file_cabinet.tscn` (FileCabinet_Standard + 3 closed drawers at y 0.035 / 0.36 / 0.685; the bare body is a hollow frame), `bookshelf_stocked.tscn` (Bookshelf, shelf tops at y 0.115 / 0.558 / 1.046 / 1.533, with books, binders and paper stacks) and `shelf_stocked.tscn` (Shelf_Base, shelves at 1.09 / 1.521, lower cubbies 0.209 left / 0.115 right). Every `FileCabinet_Standard`, `Bookshelf` and `Shelf_Base` in the tables uses them.
- `wall_clock.tscn`: the hour hand is scaled uniformly 0.65 (a non-uniform scale would warn on the hand's collision body) and the hands sit at z 0.03 (hour) / 0.038 (minute) so they don't z-fight.
- Rack box shapes: (0.58, 1.9, 0.96) at y 0.95 and (0.58, 1.84, 0.96) at y 0.92 (the scaled mesh is 0.57 × 1.90 × 0.96, centred in x and z). The racks and `pc_shelf_stack` are built but not yet looked at in-game (C1 is part 2).

**Rooms**
- Start: as planned (test chairs removed, clock 6:59).
- A2: `Divider` is a `file_cabinet`. Added (the room read as empty): a second stocked bookshelf (−4.72, 0, 7.56), a row of three `Chair_A` "waiting" in front of the door to nowhere (x −3.7, z 4.6 / 5.4 / 6.2, rot 270; 1.8 m from the fake door, outside its swing), a whiteboard on the east wall (5.865, 1.5, −4.5), a stocked shelf (5.62, 0, −6.15) and a plant (−5.35, 0, −4.2). The fake door is still the static `Door_Frame` + `Door_A` (frame at (−5.85, 0.1, 6), leaf at z 5.915); **swap it for the openable door prop when that exists.**
- A1: whiteboard x −5.865 (flush). Added: a meeting corner facing the whiteboard (`Table_Circular` (−3.6, 0, 4.5) + 3 `Chair_A`), a coffee corner by the kitchenette (`Table_Circular` (4.3, 0, −5) + 2 `Stool_A`), a stocked shelf (5.62, 0, 5), a plant (−5.3, 0, −7.3) and a stocked bookshelf on the north wall (0.6, 0, −7.56; A1 has no north door).
- A3: the clock labels run NEW YORK → DEADLINE left to right **as seen from inside** (x 3.5 → −4.5; the plan's order read backwards on the south wall). Clocks scaled 1.4 at y 2.35, labels at y 1.9, font size 64. Added: a stocked shelf (−5.62, 0, −1.8), a plant (−5.3, 0, 7.2), a small bin by the pinwheel, a floor lamp in the lounge (5.5, 0, 7.4).
- B2: giant photo at y 0.99 (its bottom on the floor). Label y 2.7, font size 96 (48 was unreadable from the door). Added: a stocked bookshelf (−5.56, 0, −4.4), a printer table + printer (−5.5, 0, 4), three plants. The 5-chair stack's top back touches the ceiling ("stacked to the ceiling").
- B1: `Door2` opens 82° instead of 35° (at 35° the leaf blocked the corridor; the player now walks through all three frames to the last door). Backwards whiteboard at z −7.77 (flush when rotated 180°). Added: two `Chair_B` and a coffee table watching the side TV (x 4.0 / 4.95, z −4), a plant (5.3, 0, −7.3), a stocked shelf (−5.62, 0, 5.5).
  - **Wall lights (user request):** the 12 ceiling lights became 9 `CeilingLight`s on the walls (`CeilingLight10–12` deleted): north wall x −3.5 / 3.5, south x −3.5 / 4.5, west z −2.2 / 5, east z −6.2 / −2.2 / 5, all at y 2.6 with rot (−90, facing, 0) (facing = wall item facing: north 0, south 180, west 90, east 270), so the panel sits flush and the spot shines horizontally into the room. SpotLight overrides (editable children): range 7.5, angle 75°, energy 3. They stay ≥ 1.2 m from doorway edges and above the whiteboard, TV and painting. No light-limit patches seen on the walls or floor.
- B3: file-tower drawers pulled out 0.25 / 0.35 / 0.45 m (x −5.42 + 0.1 i; at 0.45–0.85 the top ones floated clear of their cabinets) and each cabinet also gets its two other drawers closed. Added: a stocked bookshelf (3.4, 0, −7.56), a stocked shelf (−5.62, 0, −6.4), a plant SW and a floor lamp NE, and **four plants growing along the east wall** (scale 0.6 / 0.9 / 1.2 / 1.5 at z 3.4 → 7.2), the opposite of the shrinking desks.

- **Doors (later task):** A2's fake door and B1's four corridor/wall doors are now the openable `door.tscn` prop (all closed at start, `transom = false`; flat-on-wall ones `one_way`). A2 `FakeDoor` at (−5.775, 0.1, 5.5) rot 90 (flush, still floating 10 cm). B1 `Door1` (Door_B leaf) / `Door2` (Door_C) / `Door3` (Door_A) free-standing at x 1, z −1.75 / −3.75 / −5.75 (respaced 2 m apart so two open leaves never overlap), `LastDoor` at (1, 0, −7.775) opens into the room onto bare wall.

**Checks done:** walked all 11 doorway crossings that touch part-1 rooms plus the B1 door corridor (scripted walk, nothing snags); pushed the A2 timeout chair (rolls to the wall) and a B2 desk chair sideways (a tucked-in chair can't be pushed into its desk, as expected); no errors in the game or editor logs. Filler footprints were checked against the walkways, the 1.5 m doorway radius and the walls with a script.

**Performance:** uncapped FPS at 1152×648 (separate game process, editor open, vsync off), before → after: B2 west doorway looking east ~480 → ~430, B2 centre ~465 → ~400, Start door looking into A2 ~425 → ~355. Draw calls: 153 → 292, 145 → 454, 274 → 664. Not trimmed yet; if part 2 makes it worse, step 1 of the performance list (visibility ranges on desk clutter) is the next lever.

**For part 2:** `office.tscn` was edited as text and reloaded (the generator script lived in the agent's scratchpad, not the repo). The C rooms' `Furniture` nodes are untouched. Clocks continue the countdown: C2 6:55 (runs backwards, `minutes_per_second = -1`), C1 6:54 (C3 has no clock in the plan).

## As built (part 2)

C1, C2 and C3 are in, mostly as in the tables above. Screenshots: `screenshots/c1.png` / `c3.png` (from the west doorway), `c2.png` (from the north doorway), `c*_top.png` (top-down, ceiling hidden, north on the left, east at the top). `office.tscn` was again generated as text (scratchpad script, appended to the part-1 file) and then reloaded and saved in the editor. Deviations and additions:

**C1 (server room)**
- Lights: all 12 `Rooms/C1/Lights/CeilingLight*` have editable-children overrides: SpotLight3D `light_color` (1.0, 0.70, 0.32), `light_energy` 3.0; Panel `material_override` = new `world/office/materials/ceiling_light_panel_amber.tres` (albedo (1, 0.8, 0.5), emission (1, 0.6, 0.22) × 2.2; more saturated than a straight copy, because at × 3 the panels clipped to white).
- Flicker: `CeilingLight6` and `CeilingLight9` carry `world/office/parts/light_flicker.gd` on the instance root. Steady, then every 2–6 s a burst of 2–5 dips to 25–60 % (light energy and the panel's emission, on its own duplicated material), 0.05–0.15 s each with 0.15–0.3 s back at full in between (about 3 dips per second at most; no full-strength strobing). Story switches: `enabled = false` = steady light, `powered = false` = light off. It pauses with the game (default process mode). No buzz sound yet.
- Racks, legacy mainframe, PC stacks, PC wall, fans, AC, control desk + CRT wall, Executive chair, clock (6:54, stopped), `SwitchboardSpot` Marker3D at (5.85, 0, 1) rot 270: as planned. The sticky note is at z −0.80. The sign is font size 80 at (−3.4, 2.75, −7.86) (48 was too small, and it sits above the PC stacks).
- Added: a `LEGACY / DO NOT TOUCH` Label3D on the legacy rack's front (font 30); a whiteboard on the west wall (−5.865, 1.5, −2.4) with "DAYS SINCE / LAST BLACKOUT: / 0" (Label3D, font 64); a stocked bookshelf of "manuals" (−5.56, 0, −5) rot 90; three cardboard boxes in the NE corner (5.3, 0, −7.3 / −6.6, one stacked); two file cabinets (5.6, 0, 5.6 / 6.2) rot 270; a bin (−1.7, 0, 7.5).
- The switchboard zone (x 3.4…5.9, z −0.6…2.6) is empty; the aisle from the west door to it is ~3.6 m wide (walked, see below).

**C2 (upside-down room)**
- As planned: the ceiling pinwheel (4 `ws_modern` + 4 frozen chairs + vase + desk photo; the group's rot Z 180 mirrors the pinwheel, which doesn't matter), 4 hanging Lamp_1, the counter with coffee machine and mug, 2 plants, bin, upside-down painting (Paintings2), whiteboard and clock (6:55, `minutes_per_second = -1`). Cabinets use the `file_cabinet` prefab. The mug is at z 3.6 (3.4 was off the counter's edge).
- Added on the ceiling: a lounge corner (CoffeeTable (3.8, 3.875, 4.2) rot (0, 90, 180) and two Chair_B at x 2.9 / 4.75 facing it); an upside-down `Wall_TV` on the east wall (5.875, 2.1, −5.5) rot (0, 270, 180). Nothing new is single-sided, nothing covers a light panel, nothing hangs below ~2.3 m.
- Floor gags: the upright pushable Task chair at (−3, 0, 4.5) (pushed: rolls ~5 m, stays upright), and **`CeilingLight7` moved to the floor**: (−4, 0, 2) rot (180, 0, 0), panel up, spot shining at the ceiling (still 12 lights). It has no collision; you walk over it.

**C3 (the meeting)**
- As planned: 4 `desk_pair`s at 0 / 15 / 30 / 45°, the meeting (table, plant, projector, 5 chairs) at the end of the west walkway, four twisting paintings (Paintings2), the sandwich on PairNW's south keyboard.
- Briefcase wall is 3 / 2 / 3 (8 briefcases, middle row offset half a case like bricks) instead of 2 × 2.
- Added: a plant (5.3, 0, 7.3) and a small bin (−0.9, 0, −5.6). No clock (as planned).
- Added later: `SpinningBanana` (`world/office/props/spinning_banana.tscn`) in the NE corner at (5.4, 0, −7.4), rot Y 315 (faces the room). It's a VNB `Fruit_Banana` scaled ×3.8 (~1 m) with a yellow emissive override, on a 0.96 m navy/gold plinth (box collision) with an "EMPLOYEE OF THE YEAR" plaque and a glowing halo. It spins (`spin_speed` 0.25 turns/s) and bobs (4 cm). It has one narrow SpotLight3D of its own, not in `office_lights`, so it stays lit during blackouts.

**Checks done:** footprints of every C-room floor item checked by script against the walls, the 1.5 m doorway radius (both sides), the walkways and the switchboard zone (the only hit is the meeting circle on the west walkway's dead end, as planned). Scripted walks (separate game process, steering to waypoints): B1 → C1 west door → switchboard spot, C2 → C1 south door → aisle → switchboard, switchboard → B1, B2 → C2 → C1, C2 → C3 (north door), B3 → C3 → meeting, C3 → C2 → B2: no snags. C2's floor chair pushed 5.2 m, upright; ceiling chairs stay frozen at y 3.875. Flicker sampled for 12 s (bursts of 4 partial dips ~5 s apart; the other panels' shared material untouched). No errors in the game log.

**Performance:** uncapped FPS at 1152×648 (separate process, vsync off, editor open): C1 west door ~655, C1 aisle → switchboard ~700, C1 south door ~595, C2 west door ~635, C3 west door ~635, C3 north door ~590, B2 east door → C2 ~590. Part-1 reference spots in the same run: B2 west door ~435, B2 centre ~435, Start → A2 ~350 (unchanged from part 1). Not trimmed.


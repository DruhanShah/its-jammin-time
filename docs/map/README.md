# Office map

The whole game world is one scene, `game/world/office/office.tscn`. This page lists its rooms, their coordinates and their doors. The original hand-drawn plan is [`layout_sketch.jpeg`](layout_sketch.jpeg) (read it rotated 90° anticlockwise: the sketch's top is west here). A labelled top-down render is [`layout_topdown.png`](layout_topdown.png).

## Top-down map

North is −Z, east is +X. One character is about 1 m; `D` marks a doorway. All rooms are 12 m (x) × 16 m (z).

```
 x = -12         0           12          24          36
                 +-----------+-----------+-----------+  z = -24
                 |           |           |           |
                 |    A1     D    B1     D    C1     |
                 |           |           | SERVER /  |
                 |           |           |  GEN      |
  z = -8   +-----+-----D-----+-----D-----+-----D-----+
           |     |           |           |           |
           |START|    A2     |    B2     |    C2     |
           |     D (2 desks) D           D           |
           |     |           |           |           |
  z =  8   +-----+-----D-----+-----D-----+-----D-----+
                 |           |           |           |
                 |    A3     D    B3     D    C3     |
                 |           |           |           |
                 |           |           |           |
                 +-----------+-----------+-----------+  z = 24
```

(The ASCII is squashed: rooms are taller than they are wide.)

## Rooms

Each room is a `Node3D` under `Rooms`, placed at the room's floor centre. Its children use room-local coordinates: x −6…6, z −8…8.

| Node | What it is | Centre (x, z) | World x | World z | GridMap cells (i, k) |
|---|---|---|---|---|---|
| `Rooms/Start` | Player's own office. Only door: east, into A2 | (−6, 0) | −12…0 | −8…8 | −6…−1, −4…3 |
| `Rooms/A1` | Office room (north of A2) | (6, −16) | 0…12 | −24…−8 | 0…5, −12…−5 |
| `Rooms/B1` | Office room | (18, −16) | 12…24 | −24…−8 | 6…11, −12…−5 |
| `Rooms/C1` | **Server / generator room** ("Gen" on the sketch): `Furniture/PowerSwitch` on the east wall. From the second blackout on, the story swaps the `Rooms/C1` and `Rooms/A3` nodes' positions at load (`world/office/story_stage.gd`), so the server room stands at A3's spot | (30, −16) | 24…36 | −24…−8 | 12…17, −12…−5 |
| `Rooms/A2` | Room with two desks, entered from Start | (6, 0) | 0…12 | −8…8 | 0…5, −4…3 |
| `Rooms/B2` | Office room (straight ahead from the Start door) | (18, 0) | 12…24 | −8…8 | 6…11, −4…3 |
| `Rooms/C2` | Office room | (30, 0) | 24…36 | −8…8 | 12…17, −4…3 |
| `Rooms/A3` | Office room (south of A2) | (6, 16) | 0…12 | 8…24 | 0…5, 4…11 |
| `Rooms/B3` | Office room | (18, 16) | 12…24 | 8…24 | 6…11, 4…11 |
| `Rooms/C3` | Office room | (30, 16) | 24…36 | 8…24 | 12…17, 4…11 |

Walking out of Start into A2 you face east: A1 is on your left, A3 on your right, B2 straight ahead.

Every room has:
- `Lights`: 12 `CeilingLight`s (`world/office/parts/ceiling_light.tscn`) in a 3 × 4 grid, 4 m apart, at local x −4/0/4, z −6/−2/2/6, y 3.875.
- `Furniture`: empty Node3D for that room's props (Start has `PlayerDesk` and `Computer`).

Start room contents (room-local): `PlayerDesk` at (−4.5, 0, −1), 1.5 m from the west wall, knee side facing east; `Computer` on it at (−4.6, 0.949, −1); `DeskNarratorTrigger` at (−3, 0, −1). The player spawns at world (−7.5, 0, −1) facing west towards the desk.

## Doors

13 doorways (`WallDoorway` piece: opening 1.06 m wide, 2.67 m tall), each with an openable door (`world/office/props/door.tscn`, under `Doors`, named by the two rooms, e.g. `Doors/StartA2`; leaf swings 90° away from the player, hinge 0.44 m off the centre). Every pair of rooms that share a wall has one; Start only connects to A2. "Centre" is the world position of the middle of the opening.

| Between | Wall | Centre (x, z) |
|---|---|---|
| Start ↔ A2 | x = 0 | (0, 1) |
| A1 ↔ B1 | x = 12 | (12, −15) |
| B1 ↔ C1 | x = 24 | (24, −15) |
| A2 ↔ B2 | x = 12 | (12, 1) |
| B2 ↔ C2 | x = 24 | (24, 1) |
| A3 ↔ B3 | x = 12 | (12, 17) |
| B3 ↔ C3 | x = 24 | (24, 17) |
| A1 ↔ A2 | z = −8 | (7, −8) |
| B1 ↔ B2 | z = −8 | (19, −8) |
| C1 ↔ C2 | z = −8 | (31, −8) |
| A2 ↔ A3 | z = 8 | (7, 8) |
| B2 ↔ B3 | z = 8 | (19, 8) |
| C2 ↔ C3 | z = 8 | (31, 8) |

Doors sit 1 m off the wall's middle (walls are an even number of 2 m pieces). Keep furniture at least 1 m clear of each doorway, on both sides.

## Structure

- Doors: `Doors/<RoomRoom>` at the centres below, rot Y 90 on x-walls, 0 on z-walls.
- Three GridMaps share `world/office/gridmap/structure_library.tres`, all at the origin with cell size (2, 3.875, 2): `Floor` (item `Floor`), `Walls` (`Wall`, `WallDoorway`) and `Ceiling` (`Ceiling`, no collision). Cell (i, k) covers world x 2i…2i+2, z 2k…2k+2.
- Walls between rooms are single shared 0.2 m pieces centred on the room boundary. A cell holds one piece, so some walls are painted in the neighbouring cell (sometimes outside the building) and rotated to face back.
- `Floor` and `Walls` use octant size 2 (4 × 4 m chunks) so each chunk is lit by about 9 ceiling lights, under the Compatibility renderer's limit of 16 per object (see the "Too many lights" pitfall in [`../tutorials/placing-assets.md`](../tutorials/placing-assets.md)).

## Working on a room in parallel

Rooms are plain nodes in `office.tscn` for now. If two people need to edit different rooms at the same time, turn the room into its own scene first so you don't both edit `office.tscn`: right-click `Rooms/<Room>` → **Save Branch as Scene** → `world/office/rooms/<room>.tscn`, and commit that change alone. After that, edit the room scene. Walls, floor and ceiling stay in `office.tscn`'s GridMaps. The downside is that the walls aren't visible while you edit the room scene on its own.

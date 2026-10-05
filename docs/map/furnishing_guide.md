# Furnishing guide: VNB Low Poly Office Set (170 models)

Research by a sub-agent, scratchpad only, nothing in the repo was changed.
Path prefix for every model: `res://assets/vnb_office/models/<Name>.fbx`.

**How I checked:** I parsed every FBX with a small Python binary-FBX reader, then rendered flat-shaded thumbnails with the real palette and screen textures. The contact sheets are in this scratchpad: `sheet_0.png` to `sheet_5.png`, plus `thumbs/<Name>.png`. I cross-checked the bounds with a headless Godot import of a *scratch copy* of the asset folder (not the project), and the AABBs match Godot exactly. Composite renders: `ws_front.png`/`ws_back.png` (workstation), `asm.png` (multi-part pieces), `desks_top.png` (L-desks from above), `mainframe.png` (fake server rack options).

## 0. Facts that matter before placing anything

- **Units:** metres in Godot, scale 1 (the FBX files are in cm and the importer converts them). Every model imports with `generate/physics = true` (a static collision body).
- **Facing convention (important):**
  - **Monitors, CRTs, Wall_TV and Computer_Case** have their front/screen facing **+Z**.
  - **Chairs** (Chair_A, Chair_B, the office-chair backs) have the backrest at **−Z**, so the sitter looks toward **+Z**.
  - **Desks** have the open knee side at **+Z** and the closed modesty panel at **−Z**.
  - So for a desk at rotation 0, with its monitor facing +Z, the chair goes at +Z and is **rotated 180°** to face the desk.
- **Desk-top height is 0.949 m** for every desk, table and counter (Office_Desk_*, Table_Box, Table_Circular, Office_Counter*). The furniture is a bit oversized relative to doors (2.02 m), which is fine. Other heights: chair seats ~0.59 (office chair) / 0.715 (Chair_A, Stool_A); CoffeeTable top 0.509; FileCabinet top 1.05; Bookshelf 2.05; Shelf_Base 2.00.
  - ⚠️ **Existing bug spotted (not fixed):** `world/office/office.tscn` puts `Computer` at y = **0.75** on `Office_Desk_1` (top 0.949), so the monitor base is sunk ~0.2 m into the desk. It should be y ≈ 0.949.
- **Pivots:** most models have their origin at bottom-centre. Exceptions:
  - **Door_A/B/C and Door_Frame:** pivot at the hinge/left edge, spanning x 0 to 0.97.
  - **Wall_*:** pivot at the left end, x 0 to 2.0.
  - **Floor:** pivot at a corner, 0 to 2 in x and z.
  - **Painting, Clock, Wall_TV, WhiteBoard_Big:** centre-pivoted, so give them y = wall height you want.
  - **WhiteBoard_Stand:** board centred at the origin with legs hanging to y −1.0, so place the whole group at **y ≈ 1.0**.
  - **RFan_*** (ceiling fan): origin is the ceiling mount, so place it at ceiling y − 0.05.
  - **Chair_Office_Wheel:** centred, so it needs y = 0.056.
  - **AlcoholDisp_1:** wall-mounted, centred.
  - **Office_Files_E/F:** origin mid-height (y −0.13).
- **Multi-part ("Separated") models:**
  - **Office chair = `Chair_Office_Base_A|B|C` + `Chair_Office_Bottom` at the same origin, plus 5 × `Chair_Office_Wheel`.** Put the wheels at radius 0.36 and angles 0/72/144/216/288° from +Z, at y = 0.056: `(0.36·sinθ, 0.056, 0.36·cosθ)`, each rotated θ. Without wheels the chair floats 7 cm, so either add the wheels or drop the base+bottom by 0.07. The wheel copies (`_Copy`, `_Copy_001`…) are identical meshes, so use `Chair_Office_Wheel` five times. Base_A is a blue school/task chair, B is a black armchair, C is a high-back exec chair. **In the game, place `res://world/office/props/office_chair.tscn` instead** (already assembled, pushable, rolling sound; choose the back with its `model` property; set `freeze = true` for a chair that must stay put). Its origin is the floor centre, facing +Z like the raw parts.
  - **Shelf_Base + Shelf_Door_A/B + Shelf_Drawer, FileCabinet_* + drawers, Office_Counter* + Counter_Door/Drawer, Office_Desk_2 + Office_Desk_2_drawer + Office_Desk_Door:** the sub-parts are **not** pre-positioned (at a shared origin they sit at the floor or inside the body). They need hand offsets: drawer y ≈ 0.75 under the desk top for Desk_2, and the cabinet drawers stack in 0.32 / 0.16 steps. Shelf doors hinge at local x=0 and span to −0.45, so they need z ≈ +0.26; mirror with scale x −1 for the right door. **Cheapest:** use the bodies without doors/drawers (they read fine as open shelving), and add drawers only where an *open drawer gag* is wanted.
  - **Clock** = face (uses the BoardDocs texture with tick marks) + **Clock_A = a single clock hand** (0.155 m, pivot at its base). Two Clock_A instances = hour/minute hands, rotate around Z. Free twist/rewind gag.
  - **Small_Fan** (desk fan body) + **Small_Fan_Acc** (its 3 blades, a zero-thickness plane). **RFan_Base** + **RFan_A/B** (ceiling fan with 4 blades, grey or wood).
  - **Microwave_New/Old** + **Microwave_*_B** (its door, hinged at x 0). **Box_Base** (open cardboard box) + **Box_A/B** (flaps). **AlcoholDisp_2_Base** + `_B` (pump head) + `_C` (wall ring holder). **AlcoholDisp_1** + `_1B` (wall bracket).
  - **Office_Desk_1_Sep / _Sep2:** a desk-top divider panel and a thin plate, origin-matched to Office_Desk_1. Optional.
- **What some of the less obvious names are:**
  - Controller_1 = air-con remote; Controller_2 = TV remote.
  - Phone_A_Base = desk phone; Phone_B = cordless handset / old mobile.
  - Book_St = bookend with a leaning book.
  - Office_Files_A/B/C = paper stacks; Office_Files_D_Custom = a single document sheet (BoardDocs texture with handwriting); Office_Files_E/F = standing binders.
  - Paper_Stray = blue in/out letter tray.
  - Nature_Deco / _Small = long dark trough planter with water; Nature_Deco_2 / _2_Small = tall terracotta vase with water; Nature_Deco_3 = **the potted plant** (leafy, 0.8 m); Nature_Deco_Bamboo1/2 = 2.4 m bamboo stalks (no pot, so stand them in Nature_Deco).
  - Office_Deco = tall tapered wood vase.
  - WallShelf_Box/HRect/Rect = dark open box shelves (floor or wall); WallShelf_Simple = plank on brackets.
  - AirConditioner_A = wall split-AC unit; AirConditioner_B = a thin vent strip.
  - Stool_A = light wood bar stool; Stool_B = dark stool with an orange cushion.
  - Chair_A = light wood café chair; Chair_B = dark-wood armchair with a grey cushion.
  - Wall_Standard_Alt_1/2 = wall with wood wainscoting and blue pinstripes; Wall_Standard_Sep / Sep_2 = pillars.
- **Textures:**
  - Everything uses a 12×12 colour palette (nearest filter), so **scaling a model never blurs its texture**. That makes oversized-prop gags look clean.
  - `textures/palette1..6.png` are 6 alternative colourways. A `StandardMaterial3D` with `palette3.png` as a `material_override` recolours a whole object. **Cheap "the office repainted itself" weirdness.**
  - `screens.png` = a phone/PC lock screen (white car, "12:45") plus a desktop UI.
  - `Paintings.png` = abstract beige canvas (Painting), teal abstract (Painting_Small), and **a photo-like portrait of a real person** (Painting_Small2). Use it as the "employee of the month / boss" portrait if you like, or avoid it if you'd rather not show a real-looking face.

## 1. Inventory (all 170, W × H × D in metres, from bounds)


### Desks & tables

| Model | W x H x D (m) | Notes |
|---|---|---|
| CoffeeTable | 1.46 x 0.51 x 0.63 |  |
| Office_CounterA1 | 1.00 x 0.95 x 0.66 |  |
| Office_CounterA2 | 1.00 x 0.95 x 1.00 |  |
| Office_CounterB1 | 1.00 x 0.95 x 0.66 |  |
| Office_CounterB2 | 1.00 x 0.95 x 1.00 |  |
| Office_Desk_1 | 1.48 x 0.95 x 0.75 |  |
| Office_Desk_1_Sep | 1.37 x 0.51 x 0.63 |  |
| Office_Desk_1_Sep2 | 1.38 x 0.02 x 0.61 |  |
| Office_Desk_2 | 1.48 x 0.95 x 0.75 |  |
| Office_Desk_2_drawer | 0.63 x 0.16 x 0.74 |  |
| Office_Desk_3 | 2.37 x 0.95 x 0.75 |  |
| Office_Desk_3_Alt | 2.37 x 0.95 x 0.75 |  |
| Office_Desk_4 | 2.38 x 0.95 x 2.38 |  |
| Office_Desk_4_Alt | 2.38 x 0.95 x 2.38 |  |
| Office_Desk_4_Rounded | 2.51 x 0.95 x 2.50 |  |
| Office_Desk_4_Rounded_Alt | 2.51 x 0.95 x 2.50 |  |
| Office_Desk_4_Two | 2.38 x 0.95 x 3.39 |  |
| Office_Desk_4_Two_Alt | 2.38 x 0.95 x 3.39 |  |
| Table_Box | 0.72 x 0.95 x 0.75 |  |
| Table_Circular | 0.72 x 0.95 x 0.75 |  |

### Desk/counter sub-parts (drawers, doors, panels)

| Model | W x H x D (m) | Notes |
|---|---|---|
| Office_Counter_Door | 0.52 x 0.83 x 0.07 |  |
| Office_Counter_Drawer | 0.41 x 0.19 x 0.49 | origin offset: y from -0.10 |
| Office_Desk_Door | 0.39 x 0.86 x 0.07 | origin offset: y from -0.06 |
| Office_Desk_drawer | 0.51 x 0.16 x 0.53 |  |
| Office_Desk_drawer2 | 0.51 x 0.32 x 0.53 |  |

### Seating

| Model | W x H x D (m) | Notes |
|---|---|---|
| Chair_A | 0.61 x 1.11 x 0.68 |  |
| Chair_B | 0.72 x 0.91 x 0.62 |  |
| Chair_Office_Base_A | 0.60 x 0.74 x 0.49 | origin offset: y from 0.35 |
| Chair_Office_Base_B | 0.72 x 0.73 x 0.57 | origin offset: y from 0.36 |
| Chair_Office_Base_C | 0.72 x 0.95 x 0.60 | origin offset: y from 0.36 |
| Chair_Office_Bottom | 0.71 x 0.29 x 0.67 | origin offset: y from 0.07 |
| Chair_Office_Wheel | 0.06 x 0.10 x 0.11 | origin offset: y from -0.06 |
| Chair_Office_Wheel_Copy | 0.06 x 0.10 x 0.11 | origin offset: y from -0.06 |
| Chair_Office_Wheel_Copy_001 | 0.06 x 0.10 x 0.11 | origin offset: y from -0.06 |
| Chair_Office_Wheel_Copy_002 | 0.06 x 0.10 x 0.11 | origin offset: y from -0.06 |
| Chair_Office_Wheel_Copy_003 | 0.06 x 0.10 x 0.11 | origin offset: y from -0.06 |
| Stool_A | 0.61 x 0.71 x 0.64 |  |
| Stool_B | 0.48 x 0.72 x 0.50 |  |

### Storage

| Model | W x H x D (m) | Notes |
|---|---|---|
| Bookshelf | 1.16 x 2.05 x 0.64 |  |
| Box_A | 0.32 x 0.01 x 0.65 |  |
| Box_B | 0.38 x 0.02 x 0.65 |  |
| Box_Base | 0.65 x 0.65 x 0.65 |  |
| Briefcase_1 | 0.73 x 0.61 x 0.17 |  |
| Briefcase_2 | 0.66 x 0.60 x 0.30 | origin offset: y from -0.03 |
| FileCabinet_Small | 0.28 x 1.05 x 0.60 |  |
| FileCabinet_Small_Drawer_A | 0.22 x 0.16 x 0.58 |  |
| FileCabinet_Small_Drawer_B | 0.22 x 0.32 x 0.58 |  |
| FileCabinet_Standard | 0.57 x 1.05 x 0.53 |  |
| FileCabinet_Standard_Drawer | 0.51 x 0.32 x 0.53 |  |
| Shelf_Base | 0.99 x 2.00 x 0.55 |  |
| Shelf_Door_A | 0.44 x 0.92 x 0.07 | origin offset: y from -0.06 |
| Shelf_Door_B | 0.44 x 0.92 x 0.07 | origin offset: y from -0.06 |
| Shelf_Drawer | 0.45 x 0.16 x 0.53 |  |
| WallShelf_Box | 0.72 x 0.75 x 0.44 |  |
| WallShelf_HRect | 1.16 x 0.33 x 0.44 |  |
| WallShelf_Rect | 1.56 x 0.47 x 0.44 |  |
| WallShelf_Simple | 1.05 x 0.23 x 0.29 |  |

### Electronics

| Model | W x H x D (m) | Notes |
|---|---|---|
| AirConditioner_A | 1.40 x 0.26 x 0.36 | origin offset: y from -0.13 |
| AirConditioner_B | 1.28 x 0.07 x 0.04 | origin offset: y from -0.03 |
| CoffeeMachine | 0.47 x 0.64 x 0.67 |  |
| Computer_Case | 0.18 x 0.41 x 0.37 |  |
| Computer_Case_Old | 0.18 x 0.40 x 0.37 |  |
| Computer_Keyboard | 0.44 x 0.04 x 0.17 |  |
| Computer_Monitor | 0.40 x 0.54 x 0.16 | Screen mat |
| Computer_Mouse | 0.09 x 0.04 x 0.15 |  |
| Computer_Old | 0.44 x 0.53 x 0.33 | Screen mat |
| Computer_Old_Keyboard | 0.44 x 0.04 x 0.17 |  |
| Computer_Old_Monitor | 0.44 x 0.51 x 0.42 | Screen mat |
| Computer_old_mouse | 0.08 x 0.04 x 0.15 |  |
| Controller_1 | 0.08 x 0.03 x 0.20 |  |
| Controller_2 | 0.09 x 0.03 x 0.32 |  |
| Lamp_1 | 0.35 x 1.51 x 0.35 |  |
| Lamp_1_Small | 0.21 x 0.41 x 0.21 |  |
| Microwave_New | 0.72 x 0.47 x 0.51 |  |
| Microwave_New_B | 0.62 x 0.45 x 0.03 |  |
| Microwave_Old | 0.77 x 0.47 x 0.52 |  |
| Microwave_Old_B | 0.65 x 0.45 x 0.03 |  |
| Phone_A_Base | 0.20 x 0.06 x 0.32 |  |
| Phone_B | 0.08 x 0.30 x 0.06 | origin offset: y from -0.13 |
| Printer | 0.72 x 0.52 x 0.92 |  |
| Projector | 0.35 x 0.12 x 0.36 |  |
| RFan_A | 1.76 x 0.03 x 1.73 | origin offset: y from -0.10 |
| RFan_B | 1.76 x 0.02 x 1.73 | origin offset: y from -0.09 |
| RFan_Base | 0.21 x 0.18 x 0.22 | origin offset: y from -0.13 |
| Small_Fan | 0.21 x 0.30 x 0.22 |  |
| Small_Fan_Acc | 0.12 x 0.10 x 0.00 | origin offset: y from -0.06 |
| Wall_TV | 1.05 x 0.56 x 0.04 | origin offset: y from -0.27; Screen mat |

### Kitchen & food

| Model | W x H x D (m) | Notes |
|---|---|---|
| CoffeeCup | 0.16 x 0.12 x 0.11 |  |
| CoffeeCup_Filled | 0.16 x 0.12 x 0.11 |  |
| Food_Bread | 0.18 x 0.03 x 0.18 |  |
| Food_CheeseSlice | 0.18 x 0.01 x 0.18 |  |
| Food_CheeseSlice_2 | 0.11 x 0.01 x 0.11 |  |
| Food_CheeseSlice_3 | 0.18 x 0.03 x 0.18 |  |
| Food_CheeseSlice_Copy | 0.18 x 0.01 x 0.18 |  |
| Food_LettuceSlice | 0.22 x 0.02 x 0.22 |  |
| Food_TomatoSlice | 0.11 x 0.01 x 0.11 |  |
| Fruit_Apple | 0.10 x 0.12 x 0.11 |  |
| Fruit_Banana | 0.04 x 0.26 x 0.08 |  |
| Fruit_Banana_B | 0.04 x 0.26 x 0.08 |  |
| Fruit_Orange | 0.10 x 0.10 x 0.10 |  |
| Fruit_Plate | 0.51 x 0.19 x 0.30 |  |
| Fruit_Plate2 | 0.38 x 0.05 x 0.38 |  |
| WaterCup | 0.08 x 0.12 x 0.08 |  |
| WaterCup_Filled | 0.08 x 0.12 x 0.08 |  |

### Desk clutter & stationery

| Model | W x H x D (m) | Notes |
|---|---|---|
| AlcoholDisp_1 | 0.18 x 0.28 x 0.21 | origin offset: y from -0.12 |
| AlcoholDisp_1B | 0.20 x 0.02 x 0.25 |  |
| AlcoholDisp_2_B | 0.06 x 0.10 x 0.14 | origin offset: y from 0.31 |
| AlcoholDisp_2_Base | 0.19 x 0.31 x 0.19 |  |
| AlcoholDisp_2_C | 0.23 x 0.02 x 0.32 |  |
| Book_Big | 0.06 x 0.31 x 0.24 |  |
| Book_Fat | 0.09 x 0.26 x 0.24 |  |
| Book_FileArchive | 0.04 x 0.36 x 0.26 |  |
| Book_Folder | 0.07 x 0.34 x 0.31 |  |
| Book_Small | 0.06 x 0.25 x 0.20 |  |
| Book_St | 0.13 x 0.19 x 0.22 |  |
| Clock | 0.40 x 0.40 x 0.05 | origin offset: y from -0.20 |
| Clock_A | 0.01 x 0.16 x 0.01 |  |
| Marker | 0.02 x 0.12 x 0.02 |  |
| MarkerEraser | 0.13 x 0.03 x 0.05 |  |
| Notepad | 0.18 x 0.02 x 0.27 |  |
| Office_Files_A | 0.26 x 0.14 x 0.36 |  |
| Office_Files_B | 0.26 x 0.12 x 0.43 |  |
| Office_Files_C | 0.24 x 0.02 x 0.36 |  |
| Office_Files_D_Custom | 0.23 x 0.01 x 0.35 |  |
| Office_Files_E | 0.24 x 0.33 x 0.14 | origin offset: y from -0.13 |
| Office_Files_F | 0.24 x 0.39 x 0.14 | origin offset: y from -0.13 |
| Paper_Stray | 0.27 x 0.06 x 0.40 |  |
| Pen | 0.02 x 0.13 x 0.02 |  |
| Pencil_1 | 0.01 x 0.14 x 0.01 |  |
| Pencil_2 | 0.01 x 0.15 x 0.01 |  |
| Stapler | 0.14 x 0.04 x 0.04 |  |
| StickNote_1 | 0.12 x 0.03 x 0.14 |  |
| StickNote_2 | 0.12 x 0.04 x 0.14 |  |
| Tape | 0.05 x 0.12 x 0.17 |  |
| TrashBin | 0.36 x 0.63 x 0.31 |  |
| TrashBin_Small | 0.31 x 0.37 x 0.28 |  |

### Decor & plants

| Model | W x H x D (m) | Notes |
|---|---|---|
| Nature_Deco | 0.38 x 0.97 x 1.27 |  |
| Nature_Deco_2 | 0.31 x 0.92 x 0.31 |  |
| Nature_Deco_2_Small | 0.27 x 0.57 x 0.27 |  |
| Nature_Deco_3 | 0.80 x 0.83 x 0.77 |  |
| Nature_Deco_Bamboo1 | 0.16 x 2.43 x 1.00 |  |
| Nature_Deco_Bamboo2 | 0.17 x 2.44 x 1.04 |  |
| Nature_Deco_Small | 0.38 x 0.66 x 1.27 |  |
| Office_Deco | 0.40 x 0.76 x 0.40 |  |
| Painting | 0.87 x 0.44 x 0.03 | origin offset: y from -0.22 |
| Painting_Small | 0.25 x 0.25 x 0.04 | origin offset: y from -0.13 |
| Painting_Small2 | 0.21 x 0.25 x 0.13 | origin offset: y from -0.12 |
| Rug_A | 0.95 x 0.00 x 0.50 |  |
| Rug_B | 0.95 x 0.02 x 0.50 |  |
| WhiteBoard_Big | 2.06 x 1.04 x 0.16 | origin offset: y from -0.52 |
| WhiteBoard_Stand | 0.83 x 1.04 x 0.14 | origin offset: y from -0.52 |
| WhiteBoard_Stand_1 | 0.04 x 1.03 x 0.04 | origin offset: y from -1.00 |
| WhiteBoard_Stand_2 | 0.04 x 1.15 x 0.04 | origin offset: y from -1.00 |
| WhiteBoard_Stand_Base | 0.10 x 0.10 x 0.07 | origin offset: y from -0.04 |

### Architecture

| Model | W x H x D (m) | Notes |
|---|---|---|
| Door_A | 0.97 x 2.02 x 0.09 |  |
| Door_B | 0.97 x 2.02 x 0.09 |  |
| Door_C | 0.97 x 2.02 x 0.09 |  |
| Door_Frame | 1.14 x 2.10 x 0.25 |  |
| Door_Handle1 | 0.21 x 0.05 x 0.10 | origin offset: y from -0.02 |
| Door_Handle2 | 0.77 x 0.05 x 0.09 | origin offset: y from -0.02 |
| Floor | 2.00 x 0.04 x 2.00 | origin offset: y from -0.04 |
| Wall_Medium | 2.00 x 2.50 x 0.08 |  |
| Wall_Medium_Door | 2.00 x 2.50 x 0.08 |  |
| Wall_Small | 2.00 x 1.75 x 0.08 |  |
| Wall_Standard | 2.00 x 3.00 x 0.20 |  |
| Wall_Standard_Alt_1 | 2.00 x 3.00 x 0.40 |  |
| Wall_Standard_Alt_2 | 2.00 x 3.00 x 0.40 |  |
| Wall_Standard_Door | 2.00 x 3.00 x 0.20 |  |
| Wall_Standard_Sep | 0.15 x 3.04 x 0.27 |  |
| Wall_Standard_Sep_2 | 0.31 x 3.02 x 0.38 |  |

UNCATEGORISED: []

## 2. Server room ("Gen"): honest answer

**There are no server racks, mainframes, generators, switchboards or big machines in this pack.** The largest "machines" are: Printer (0.72 × 0.52 × 0.92, desk-top size), CoffeeMachine (0.47 × 0.63 × 0.67), Microwave_New/Old, AirConditioner_A (1.40 m wall unit), Projector, Wall_TV, Computer_Case / Computer_Case_Old (0.41 m PC towers) and the CRTs.

**But a convincing fake is cheap.** See `mainframe.png`.

- **`Computer_Case` with a non-uniform scale of about (3.2, 4.6, 2.6)** comes out at 0.57 × 1.89 × 0.96 m. That is a black cabinet with drive-bay slits and a power button, and in a row of 4–6 it reads clearly as a **server rack**. `Computer_Case_Old` at the same scale gives a **beige 70s mainframe**. Mix 1 beige into a row of black ones for a "legacy system" joke. Spacing: 0.62 m on centres. The front faces +Z.
- **Rack shelving:** stack `WallShelf_Box` (dark open cube, 0.72 × 0.75 × 0.44) 2–3 high, with an unscaled `Computer_Case` rotated 90° in each cube. It reads as a rack with servers in it.
- **`Shelf_Base`** (2.0 m grey metal cabinet) reads as a tall utility cabinet / breaker cabinet. **`FileCabinet_Standard`** (grey, 1.05 m) works as a low cabinet.
- **"Wall of old monitors":** stack `Computer_Old_Monitor` / `Computer_Old` 2 high in rows, which gives a monitoring station / control-room vibe. Give the screens an emissive material (see §6).
- **AirConditioner_A** on the wall adds server-room cooling; **AirConditioner_B** vent strips; **Small_Fan** units on the floor pointed at the racks (comic "cooling").
- **Switchboard:** nothing in the pack. Candidates for a stand-in are `Shelf_Base` with `Shelf_Door_A/B` (a grey cabinet with doors, which fits the "twist screws to open switchboard" beat), or `FileCabinet_Small`. The wires/panel must be custom (CSG or a 2D minigame).
- **Recommendation for the "only fill it if we have assets" rule:** we *don't* have real mainframes. **Either** do the scaled-Computer_Case racks (I think they look good; they cost almost nothing) **or** leave Gen sparse: one Shelf_Base "switchboard" cabinet, an AC unit and some boxes (`Box_Base`). If you scale non-uniformly, replace the auto-generated collision with a `BoxShape3D` (Godot warns about non-uniformly scaled collision shapes).

## 3. Workstation recipes (offsets relative to the desk origin)

All recipes assume desk rotation 0: the knee side is +Z and the user sits at +Z looking toward −Z. Desk top is **y = 0.949**. Rotate the whole group as one Node3D. Verified visually in `ws_front.png` / `ws_back.png`.

**A. Modern single (Office_Desk_1 or Office_Desk_2, 1.48 × 0.75):**

| Item | Position (x, y, z) | Rot Y |
|---|---|---|
| Computer_Monitor | (0, 0.949, −0.20) | 0 |
| Computer_Keyboard | (0, 0.949, 0.12) | 0 |
| Computer_Mouse | (0.33, 0.949, 0.12) | 0 |
| Computer_Case (under desk) | (0.50, 0, −0.10) | 0 |
| Lamp_1_Small (desk lamp, red shade) | (−0.55, 0.949, −0.22) | 0 |
| CoffeeCup_Filled | (0.55, 0.949, 0.05) | any |
| Notepad / StickNote_1 / Pen | (−0.30, 0.949, 0.10) | ~15° |
| Office chair (Base_B + Bottom + 5 wheels) | (0, 0, 0.75) | **180°** |
| TrashBin_Small | (−0.85, 0, 0.30) | 0 |
| Nature_Deco_3 (plant) next to desk | (1.20, 0, −0.10) | 0 |

**B. Retro 90s single:**
- On Office_Desk_2 or Table_Box: `Computer_Old` (all-in-one CRT on a base) at (0, 0.949, −0.12), or `Computer_Old_Monitor` at (0, 0.949, 0.0).
- `Computer_Old_Keyboard` at (0, 0.949, 0.22) and `Computer_old_mouse` at (0.33, 0.949, 0.22).
- `Computer_Case_Old` under the desk; Chair_B at (0, 0, 0.70) rotated 180°; Phone_A_Base at (−0.5, 0.949, −0.1).

**C. Two-seat bench (Office_Desk_3 or _3_Alt, 2.37 wide):** recipe A twice, at x = −0.6 and x = +0.6, with no lamp. Chairs at (±0.6, 0, 0.75) rotated 180°.

**D. L-desk (Office_Desk_4 / _Alt / _Rounded / _Rounded_Alt; `_Two` has a longer return arm to z 3.0).** Main arm along X (z ±0.375), return arm along +Z on the −X side (x −1.2…−0.45, out to z ≈ 2.0). The user sits in the inside corner.
- Main monitor at (0.3, 0.949, −0.2), rotation 0. Chair at (0.2, 0, 0.85) rotated 180°.
- Second monitor on the return arm at (−0.85, 0.949, 1.1) rotated **+90°** (faces +X).
- Printer or Paper_Stray at the far end of the return arm at (−0.85, 0.949, 1.7).
- Good "manager desk". A **Rounded** variant plus Chair_Office_Base_C (high back) makes a boss desk.

**E. Four-desk pod (2 × 2 back-to-back):**
- Office_Desk_1 at (±0.74, 0, −0.375) rotated **180°**, and at (±0.74, 0, +0.375) rotation 0. The modesty panels meet in the middle.
- Each desk gets recipe A in its own local frame, so the chairs end up at z ≈ ±1.125.
- `Office_Desk_1_Sep` is a desk-top divider if wanted. Footprint about 3.0 × 3.0 m including chairs.

**F. Eight desks:** two E-pods, or **4 × Office_Desk_3 in classroom rows all facing the same wall** (rows 1.8 m apart). Rows facing one wall feel slightly institutional, which is good for mid-game.

Small extras that sell a desk: Paper_Stray (in-tray), Office_Files_A/B (paper stacks), Office_Files_E/F (binders, raise by +0.13 since their origin is mid-height), Stapler, Tape, Book_St, Phone_A_Base, WaterCup_Filled, Fruit_Apple, Small_Fan (desk fan, 0.30 tall).

## 4. Weirdness ladder (only models we have)

✅ = cheap (one transform / a duplicate). ⚙️ = needs a tiny script or material tweak. Keep it funny, not scary.

**Tier 0: Normal (start room, 1 desk + plant).**
- Recipe A, a plant (Nature_Deco_3), a Clock on the wall, a WaterCup, Painting (the abstract one), a Rug_A under the desk.
- Should look clean and believable so the later deviations register.
- ✅ One micro-seed: the mug is at the exact spot that will repeat later (remember its local offset, e.g. (0.55, 0.949, 0.05)).

**Tier 1: Slightly off (2-desk room and the first 4-desk room).** These are things players notice on a second look.
- ✅ A chair facing the wall (or facing away from its desk) at a perfectly neat position.
- ✅ **Identical-twin desks:** every desk has the mug, notepad, pen and sticky note at *exactly* the same offsets, and the chairs are all pulled out by the same 0.75 m. Uncanny precision is the joke.
- ✅ A monitor turned 180° (screen to the wall) on one desk; a keyboard on the chair seat (y 0.59).
- ✅ The clock shows a "wrong" time: two `Clock_A` hands at odd angles. ⚙️ Rotating one hand slowly backwards fits the twist theme.
- ✅ A lone plant on a chair seat, tucked in at the desk like an employee (Nature_Deco_3 at seat height, chair rotated to the desk). Pairs with "your coworker Fern" narration.
- ✅ One extra door (`Door_Frame` + `Door_A`) flush on a wall that clearly leads nowhere, just slightly too narrow or too high (y +0.1).
- ⚙️ The whole room uses `palette2.png` instead of palette1: same furniture, subtly different colours.

**Tier 2: Uncanny (the remaining 4-desk rooms and the 8-desk rooms).** These are obviously wrong but plausible as office pranks.
- ✅ **Chair stacks:** Chair_A ×4–6 stacked (each next chair at y + 0.715 on the seat of the one below, small random yaw ±8°). Also a column of TrashBins, a tower of Box_Base, or WaterCups stacked into a pyramid on a desk.
- ✅ **Plant in a filing cabinet:** a FileCabinet_Standard_Drawer pulled out (z +0.3) with Nature_Deco_3 at scale 0.6 sitting inside. Bamboo (Nature_Deco_Bamboo1, 2.4 m) growing out of a Box_Base or a TrashBin.
- ✅ **Door frame with no wall:** a `Door_Frame` (+ `Door_B` half-open, rotated 60°) standing alone in the middle of the room. Perfect for the "bunch of extra doors" beat. Several of them in a row is even better.
- ✅ **8 desks, 8 chairs, 8 identical mugs, and one desk has a chair and nothing else.** Or the reverse: eight monitors on a single Office_Desk_3, shoulder to shoulder.
- ✅ **Tilted furniture:** a desk tipped 8–12° on Z (one side propped on a Book_Fat), a bookshelf leaning 5° on a wall, a painting rotated 15° (classic "crooked painting"), or a painting rotated 90°.
- ✅ **Oversized prop:** a CoffeeCup at scale 6–8 (≈1 m tall) used as a "planter" with Nature_Deco_3 inside, or a giant Stapler / Pencil_1 (scale 15 makes a 2 m pencil leaning on a wall). A Fruit_Banana at scale 8 lying on a desk. Palette textures stay crisp at any scale.
- ✅ **Tiny furniture:** a full recipe-A workstation at scale 0.15 sitting on a real desk (a doll-house office), maybe with its own tiny Lamp_1_Small.
- ✅ A ceiling fan (RFan_Base + RFan_A) mounted on a *wall*, rotated 90°. ⚙️ Spin it.
- ✅ Whiteboard (WhiteBoard_Stand group) facing the wall; Office_Files_D_Custom documents taped to the ceiling (rotate 180° on X so the textured face points down).
- ✅ A row of 8 desks that gets a little shorter each time (scale 1.0 → 0.65), like perspective lying.

**Tier 3: Absurd (the last desk room before Gen, and the route toward the switchboard).**
- ✅ **Desk on the ceiling:** a complete workstation (desk, chair, monitor, mug) rotated 180° on X at ceiling height, so the desk-top surface ends up at y ≈ ceiling − 0.949. Do not include the rug (see §6, backface culling) unless you flip it.
- ✅ **Sideways office:** a workstation group rotated 90° on Z and bolted to a wall, so the chair "sits" on the wall.
- ✅ **Desk sculpture:** 6–10 chairs radially arranged *facing a single potted plant*, as if in a meeting, with a Projector on the floor pointed at the plant. Or a meeting of chairs facing a Wall_TV leaning on the floor.
- ✅ **Infinite filing:** FileCabinet_Standard stacked 3 high to the ceiling with every drawer pulled out to a different depth (a staircase); an Office_CounterA2 with a Microwave_Old inside a Microwave_New (scale 0.8).
- ✅ **Floor lamp forest:** 10–15 Lamp_1 (1.5 m floor lamps) standing in a grid in an otherwise empty room. Very on-theme, since light is the antagonist. ⚙️ Optionally only one has a real OmniLight.
- ✅ **A lone monitor in an empty room** on a Table_Circular, facing the entrance, with the chair facing it from 4 m away. ⚙️ Emissive screen.
- ✅ **Dinner on a desk:** Food_Bread + Food_CheeseSlice + Food_LettuceSlice + Food_TomatoSlice stacked as a sandwich on a keyboard. Fruit_Plate on an office chair seat. Mildly silly.
- ✅ **Bamboo forest** (Bamboo1/2 ×12, random yaw) growing between desks, with a Door_Frame in the middle of it.
- ✅ **Briefcases** (Briefcase_1/2) stacked like bricks to form a short wall.
- ⚙️ **Mannequin stand-ins** (no mannequins exist; see §5): an office chair with a Lamp_1_Small as a "head" on the seat-back and a Briefcase on its lap reads as a seated "colleague" silhouette. Put 4 of them around a desk pod. Funny, not creepy, if the lampshades are the bright red ones.

**Tier 4: Gen / server room.** Fake racks (§2) in tidy rows, a single beige "legacy" one, AC unit, desk fans pointing at the racks, a Shelf_Base "switchboard". For the second and third visits (the switchboard has moved), reuse the Tier 3 tricks: the cabinet is now on the ceiling or in a doorframe with no wall.

**Suggested progression by sketch position:**
- Start room (top): Tier 0.
- Second row: the middle room is the door hub, Tier 1 with an extra door; the left and right rooms use Tier 1 props.
- Third row: Tier 2, one gag per room, mixing palettes.
- Bottom row: left Tier 2–3, middle Tier 3, Gen Tier 4.
- **One headline gag per room** plus 1–2 small ones keeps rooms different without clutter.

## 5. Assets for the plan's mechanics

| Plan item | In pack? | Closest model / note |
|---|---|---|
| Light switch | ❌ | None. Use a small CSG box on the wall, or `Door_Handle1` turned 90° as a lever, or `Phone_A_Base` buttons. |
| Switchboard | ❌ | `Shelf_Base` (+ `Shelf_Door_A/B`) as a grey metal cabinet; `FileCabinet_Small`. |
| Candle | ❌ | None. `Marker` (0.12 m) or `Pencil_1` stood upright with a small OmniLight plus a flame sprite could pass; or a WaterCup as a candle holder. |
| Binoculars / kaleidoscope | ❌ | None. `Tape` (a teal ring) ×2 side by side reads vaguely binocular-ish; better to model it in CSG (2 cylinders). |
| Glasses | ❌ | None. |
| Lamp | ✅ | `Lamp_1` (1.51 m floor lamp), `Lamp_1_Small` (0.41 m desk lamp). They have no light source, so add an OmniLight3D/SpotLight3D at the shade (≈ y 1.40 / 0.33). |
| Ceiling light | (repo) | Already have `world/office/parts/ceiling_light.tscn`. |
| Garden gnome / imp | ❌ | None. A wobbling `Office_Deco` or `Nature_Deco_2_Small` vase could stand in until a gnome exists. |
| Mannequin | ❌ | None (see Tier 3 stand-in idea). |
| Genie lamp | ❌ | Nothing lamp-shaped. `CoffeeCup` or `AlcoholDisp_2_Base` (a red-capped bottle) are the closest "vessel" shapes. |
| Sphinx | ❌ | None. |
| Yellow brick road | ❌ | `Floor` tile (2 × 2 m) with a yellow palette swatch, or `Rug_A/B`, or `StickNote_1` ×N (yellow sticky notes laid as a path). Cheap and funny. |
| Sticky note with password | ✅ | `StickNote_1/2` (yellow); `Office_Files_D_Custom` has handwriting on it. |
| Clock (rewind/loop) | ✅ | `Clock` + 2 × `Clock_A` hands (rotatable). |
| Button | ❌ | Not a big button. `Phone_A_Base` or `Projector` (it has buttons), or a CSG button. |
| Computer | ✅ | `Computer_Monitor`, `Computer_Old`, `Wall_TV` (side monitor with "subway surfers"). |
| Doors (extra doors) | ✅ | `Door_A` (solid), `Door_B` (small window hole), `Door_C` (tall window hole), `Door_Frame`, `Door_Handle1/2`, `Wall_*_Door`. |
| Key / torch | ❌ | None. |
| Pay/bank (sleep money) | – | Not applicable. `Briefcase` for "money". |

## 6. Rendering concerns

- **No emissive materials.** `materials/screen.tres` is albedo-only. Monitors, CRTs and Wall_TV go dark when the lights go out, which the light-antagonist gameplay needs to know about. For glowing screens, create a *new* material (don't edit the shared `screen.tres`): `emission_enabled = true`, `emission_texture = screens.png`, energy 1–2, applied via `surface_material_override` on the Screen surface. Then a dark room with one glowing monitor is very cheap atmosphere. The screen UVs show a car/lock-screen image ("12:45") or a desktop UI. You may want your own texture with Comic Sans.
- **No transparency anywhere.** The "water" in WaterCup_Filled, Nature_Deco and Nature_Deco_2 is an opaque blue palette swatch. Door_B/C windows are real holes with no glass, and there is no glass material. Nothing to worry about for sorting.
- **Single-sided planes vanish from behind** (backface culling): Rug_A (zero thickness), Box_A/B flaps, Small_Fan_Acc blades, AirConditioner_B, the Floor tile underside, Office_Files_D_Custom, and thin Painting backs. Upside-down or ceiling placements need them flipped toward the viewer, or set `cull_mode = disabled` on an override material.
- **Lamps are meshes only.** Add Godot lights yourself. The project is on the Compatibility renderer with no real-time shadows (SSAO), so many OmniLights in a "lamp forest" are fine visually but count against the per-object light limit; keep each OmniLight's range small.
- **Collision:**
  - Every model has an auto-generated static body. A desk on the ceiling or a giant cup still collides, which is fine, but tiny clutter (pens, wheels) also gets bodies. Harmless to the player (0.3 m capsule), and the interact ray only hits layer 2.
  - **Non-uniformly scaled models** (fake racks) should get a hand-made `BoxShape3D` instead of the scaled auto-shape.
  - Stacked/tilted furniture may make the player snag; leave walking room.
- **Negative scale (mirroring a shelf door):** Godot handles the winding flip, but the collision shape warns, so prefer rotation where possible.
- **Painting_Small2** shows a photographic portrait of a real-looking person. Consider whether you want it in the game; it could be swapped for a custom painting texture.
- The **palette swap** trick (§0) needs a separate material resource per palette (e.g. `palette3_mat.tres`) used as `material_override`. Don't change the shared `materials/palette.tres`, since every model in the game uses it.

extends Control
## Ending: the credits roll. Comic panels (paper, thick outline, offset shadow, yellow caption) scroll
## up over a halftone sky: the primary credits, MORE CREDITS!!!!, then every shipped external asset
## and its licence (kept in step with game/CREDITS.md), then THE END. THE END stops in the middle of the
## screen, the narrator signs off and the end screen offers Quit (desktop only: a web page can't
## close itself, so on the web it just stays). Hold Space, Enter or the mouse button to fast-forward.
##
## To add a credit: add a line to the right section of `SECTIONS` (and to game/CREDITS.md).

## Sections, top to bottom. [caption, lines] is a comic panel; [caption] alone is a big tilted banner;
## [caption, lines, true] is a small-print panel (the asset list). Line formats:
##   "# Name"        a big name, centred
##   "Role|Name"     a credit row: role on the left, name on the right
##   "* Item"        an item in a two-column grid (small print)
##   anything else   small print, wrapped
const SECTIONS: Array = [
	["PRIMARY CREDITS"],
	["CODE", [
		"# Claude",
		"# Arnav",
		"# Vishesh",
		"# Kimaya",
	]],
	["VOICE", [
		"The Narrator|Druhan Shah",
		"Stupid! Narrator|Nandini",
		"Sarcastic Narrator|Vishesh",
		"Initial Narrator|Arnav",
		"Special Thanks|Druhan Shah (aka Arnav Gupta)",
	]],
	["SCRIPT", [
		"# Druhan Shah",
		"# Vishesh",
		"# Arnav Gupta",
	]],
	["VIDEO", [
		"Protagonist|Arnav",
		"Skyrim NPC|Druhan Shah",
		"Vishesh|Vishesh",
	]],
	["MUSIC", [
		"# Kevin MacLeod",
		"youtube.com/channel/UCSZXFhRIx6b0dFX3xS8L1yQ",
	]],
	["MORE CREDITS!!!!"],
	["VOICE", [
		"Narrator|Druhan Shah",
		"Gargoyle 1|Druhan Shah",
		"Gargoyle 2|Druhan Shah",
		"Narrator (Sleep deprived)|Druhan Shah",
		"Narrator (for real this time)|Druhan Shah",
		"Game Show Host|Amitabh Bacchan (jk, it's Druhan Shah)",
		"Special thanks to|Druhan Shah (who was actually Arnav Gupta all along)",
		"Mild Annoyances|Three minions in a trench coat",
		"Placeholder credit|I'm just throwing credits here to pad for space",
		"Placeholder credit|Did you know that the weight of all ants in the world is the same as the weight of all humans in the world",
		"Placeholder credit|How's your day going by the way?",
	]],
	["VIDEO", [
		"Protagonist|Arnav Gupta",
		"Skyrim NPC|Druhan Shah",
		"Druhan Shah|Vishesh Saraswat",
	]],
	["SAFETY NOTICE", [
		"No lights were harmed in the making of this game.",
		"Several were inconvenienced.",
	]],
	["ASSETS"],
	["3D MODELS", [
		"Low Poly 3D Office Set [VNB] by VNB (Leo), vnbp.itch.io/low-poly-3d-office-set-vnb, CC BY 4.0",
		"\"Candle\" by Nick Slough, poly.pizza/m/HFpLq6iqKu, CC BY 3.0",
		"\"Binoculars\" by Ryan Sullivan, poly.pizza/m/fd1MPYUTpLL, CC BY 3.0",
		"\"Steampunk pipes\" by Phiam Ash, poly.pizza/m/aBug7Q_ZiS_, CC BY 3.0",
		"PSX First Person Arms by Drillimpact, drillimpact.itch.io/psx-first-person-arms-free, CC0",
		"\"Screwdriver\" by CreativeTrio, poly.pizza/m/qBFMjkrKzH, CC0",
		"\"Glasses\" by iPoly3D, poly.pizza/m/p5QgQxkMBE, CC0",
		"\"Demon\" (x2, the gargoyles) and \"Pedestal\" by Quaternius, poly.pizza, CC0",
	], true],
	["FONTS", [
		"Comic Neue by Craig Rozynski & Hrant Papazian, © 2014 The Comic Neue Project Authors, github.com/crozynski/comicneue, SIL OFL 1.1",
		"Comic Relief by Jeff Davis, © 2013 The Comic Relief Project Authors, github.com/loudifier/Comic-Relief, SIL OFL 1.1",
		"Comic Shanns Mono, © 2018 Shannon Miwa, © 2023 Jesus Gonzalez, github.com/jesusmgg/comic-shanns-mono, MIT License",
		"Tinos (© 2026 The Tinos Project Authors), Arimo (© 2026 The Arimo Project Authors), EB Garamond (© 2017 The EB Garamond Project Authors), Anton (© 2020 The Anton Project Authors): SIL OFL 1.1",
		"Office Sans Jam, modified from Carlito (© 2013 The Carlito Project Authors, Reserved Font Name \"Carlito\"), SIL OFL 1.1",
		"Almendra by Ana Sanfelippo, © 2011-2012, SIL OFL 1.1",
		"Jamdings: glyphs from Noto Sans Symbols, © 2022 The Noto Project Authors, SIL OFL 1.1",
		"DejaVu Sans: Bitstream Vera Fonts © 2003 Bitstream, Inc., DejaVu changes public domain, DejaVu font licence",
		"Comic Sans MS is not used; it is licensed by Microsoft. Times New Roman, Arial, Helvetica, Calibri, Papyrus, Impact, Wingdings and Comic Sans are trademarks of their respective owners. None of those fonts are included.",
	], true],
	["SOUNDS", [
		"400 Sounds Pack by Chequered Ink, ci.itch.io/400-sounds-pack",
		"Interface Sounds by Kenney, kenney.nl, CC0",
		"From Freesound (freesound.org), all CC0:",
		"* \"rolling_office_chair.WAV\" by alpanaytekin",
		"* \"Screwdriver 1\" by 16GPanskaToman_Kristian",
		"* \"Bolts into Iron Pipe Flange\" by zembacraftworks",
		"* vent cover removal by ME_Studios_Official",
		"* \"Electricity Sound\" by NachtmahrTV",
		"* \"plug getting connected to wall socket\" by preyk",
		"* \"Electric zap.wav\" by michael_grinnell",
		"* \"Spark\" by elliott.klein",
		"* \"switch big breaker metal click\" by kyles",
		"* \"Neon Lamp, Switch On, Hum\" by Kinoton",
		"* \"squeak_01.wav\" by joedeshon",
		"* rusty wheel loop and leather creaks by Nox_Sound",
		"* \"Hitting a Pipe with a Hammer\" by brittmosel",
		"* \"Pressure Meter Pipe Noises 1\" by RutgerMuller",
		"* \"high-voltage.wav\" by fkurz",
		"* \"Wrong Buzzer\" by KevinVG207",
		"* \"quiz game music loop BPM 90\" by portwain",
		"* \"heartbeat-60bpm\" by loudernoises",
		"* \"S_Spotlight_On\" by Grubzyy",
		"* \"Cinematic Hit With Horns\" by DeVern",
		"* \"DSGNStngr_basic trailer boom impact\" by harrisonlace",
		"* \"Correct.wav\" by bwg2020",
		"* \"Good answer harp glissando\" by oggraphics",
		"* \"Heavy stone door opens 2\" by PostProdDog",
		"* \"Rumble · fade in 10s\" by unfa",
		"* \"Basic Fire whoosh\" by LookIMadeAThing",
		"* \"fire crackling loop.wav\" by soundofsong",
		"* \"Socket Wrench\" by xxqmanxx",
	], true],
	["MUSIC", [
		"\"Piece for Disaffected Piano Two\" Kevin MacLeod (incompetech.com), Licensed under Creative Commons: By Attribution 4.0 License, creativecommons.org/licenses/by/4.0/",
		"\"Cheerful Comedy Funny Quirky Background\" by alex-morgan (Pixabay), pixabay.com/music/cartoons-cheerful-comedy-funny-quirky-background-587373/, Pixabay Content License",
	], true],
	["MADE BY THE TEAM", [
		"Start screen art: hand-drawn by Kimaya Arora",
		"Character select art: drawn by Nandini Chakaravarthy",
		"Real-life ending video: filmed by the team",
		"Narrator voices: recorded by the team",
		"Cursor, halftone shader, ceiling texture, all scripts and scenes: made for this game",
	], true],
	["ENGINE", [
		"Made with Godot Engine, godotengine.org, MIT License (godotengine.org/license)",
		"Godot logo by Andrea Calabró, godotengine.org/press, CC BY 4.0",
		"Licences: CC BY 3.0 creativecommons.org/licenses/by/3.0/, CC BY 4.0 creativecommons.org/licenses/by/4.0/, SIL OFL 1.1 openfontlicense.org",
		"Built with the help of editor plugins: Godot AI, Godot Asset Placer, Snappy (MIT)",
	], true],
]

const CAPTION_FONT := preload("res://assets/fonts/ComicRelief-Bold.ttf")
const NAME_FONT := preload("res://assets/fonts/ComicNeue-Bold.ttf")
const BODY_FONT := preload("res://assets/fonts/ComicNeue-Regular.ttf")
const HALFTONE := preload("res://core/ui/comic/halftone.gdshader")
const PAPER := Color("#fff8e7")
const CAPTION := Color("#ffd23f")
const INK := Color("#141018")

## Scroll speed in pixels per second (at the 648 px base height), and how much faster while held.
@export var speed := 70.0
@export var fast_forward := 6.0
## Seconds THE END holds before the end screen's buttons appear.
@export var end_hold := 2.5

var _roll: VBoxContainer
var _the_end: Control
var _end_box: VBoxContainer
var _y := 0.0
var _stopped := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	Audio.crossfade_to(Audio.MENU_MUSIC, 1.0, 1.5) # The opening music again, looping under the roll.
	_build_background()
	_roll = VBoxContainer.new()
	_roll.add_theme_constant_override(&"separation", 56)
	_roll.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_roll)
	_roll.add_child(_caption_only("MEANWHILE, IN THE CREDITS..."))
	for section: Array in SECTIONS:
		if section.size() == 1:
			_roll.add_child(_caption_only(section[0], 44))
		else:
			_roll.add_child(_panel(section[0], section[1], section.size() > 2 and section[2]))
	_the_end = _make_the_end()
	_roll.add_child(_the_end)
	_build_end_box()
	_y = get_viewport_rect().size.y + 20.0
	_layout()
	resized.connect(_layout)


func _process(delta: float) -> void:
	if _stopped:
		return
	var screen_height := get_viewport_rect().size.y
	var held := Input.is_action_pressed(&"ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_y -= speed * (fast_forward if held else 1.0) * delta * (screen_height / 648.0)
	var end_center := _y + _the_end.position.y + _the_end.size.y * 0.5
	if _the_end.size.y > 0.0 and end_center <= screen_height * 0.4:
		_y -= end_center - screen_height * 0.4
		_stop()
	_roll.position.y = _y


func _layout() -> void:
	var screen := get_viewport_rect().size
	var width := minf(760.0, screen.x - 32.0)
	_roll.custom_minimum_size.x = width
	_roll.size = Vector2(width, 0)
	_roll.position.x = (screen.x - width) * 0.5
	_roll.position.y = _y


func _stop() -> void:
	_stopped = true
	var tween := create_tween()
	tween.tween_property(_the_end, "scale", Vector2.ONE * 1.15, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_the_end, "scale", Vector2.ONE, 0.2)
	tween.tween_interval(end_hold)
	tween.tween_callback(_show_end_box)


func _show_end_box() -> void:
	_end_box.visible = true
	_end_box.modulate.a = 0.0
	create_tween().tween_property(_end_box, "modulate:a", 1.0, 0.4)
	var quit := _end_box.get_node_or_null(^"Quit") as Button
	if quit:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		ComicCursor.apply()
		quit.grab_focus()


func _quit() -> void:
	ComicCursor.reset() # Frees the custom cursor's textures before the engine shuts down.
	get_tree().quit()


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = HALFTONE
	material.set_shader_parameter(&"paper_color", Color("#7ec8f2"))
	material.set_shader_parameter(&"dot_color", Color("#4a9be0"))
	material.set_shader_parameter(&"radial", 1.0)
	material.set_shader_parameter(&"cell_size", 18.0)
	bg.material = material
	add_child(bg)


## A comic caption box on its own (yellow, outlined, slightly tilted).
func _caption_only(text: String, size_px := 30) -> Control:
	var holder := CenterContainer.new()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(&"panel", _style(CAPTION, 4, 6, 14))
	box.rotation_degrees = -2.0
	box.add_child(_label(text, CAPTION_FONT, size_px, INK, HORIZONTAL_ALIGNMENT_CENTER, false))
	holder.add_child(box)
	return holder


## A panel: caption on the top edge, then names, credit rows or small print (smaller when `small`).
func _panel(caption: String, lines: Array, small := false) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", _style(PAPER, 5, 9, 22 if small else 26))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6 if small else 10)
	panel.add_child(box)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override(&"panel", _style(CAPTION, 3, 0, 8))
	head.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(_label(caption, CAPTION_FONT, 24, INK, HORIZONTAL_ALIGNMENT_LEFT, false))
	box.add_child(head)
	var body_size := 15 if small else 19
	var grid: GridContainer = null
	for line: String in lines:
		if line.begins_with("* "):
			if grid == null:
				grid = GridContainer.new()
				grid.columns = 2
				grid.add_theme_constant_override(&"h_separation", 18)
				grid.add_theme_constant_override(&"v_separation", 2)
				box.add_child(grid)
			var item := _label(line.substr(2), BODY_FONT, body_size - 1, INK, HORIZONTAL_ALIGNMENT_LEFT)
			item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(item)
			continue
		grid = null
		if line.begins_with("# "):
			box.add_child(_label(line.substr(2), NAME_FONT, 38, INK, HORIZONTAL_ALIGNMENT_CENTER))
		elif "|" in line:
			box.add_child(_role_row(line.get_slice("|", 0), line.get_slice("|", 1)))
		else:
			box.add_child(_label(line, BODY_FONT, body_size, INK, HORIZONTAL_ALIGNMENT_CENTER if not small else HORIZONTAL_ALIGNMENT_LEFT))
	return panel


## Film-credit row: role right-aligned on the left half, name left-aligned on the right half.
func _role_row(role: String, who: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 22)
	var left := _label(role, BODY_FONT, 20, Color(INK, 0.75), HORIZONTAL_ALIGNMENT_RIGHT)
	var right := _label(who, NAME_FONT, 24, INK, HORIZONTAL_ALIGNMENT_LEFT)
	for label: Label in [left, right]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)
	return row


func _make_the_end() -> Control:
	var holder := CenterContainer.new()
	holder.custom_minimum_size.y = 220.0
	var label := _label("THE END", CAPTION_FONT, 96, Color("#ff3b30"), HORIZONTAL_ALIGNMENT_CENTER, false)
	label.add_theme_constant_override(&"outline_size", 22)
	label.add_theme_color_override(&"font_outline_color", INK)
	label.add_theme_constant_override(&"shadow_offset_x", 8)
	label.add_theme_constant_override(&"shadow_offset_y", 8)
	label.add_theme_color_override(&"font_shadow_color", INK)
	label.rotation_degrees = -4.0
	holder.add_child(label)
	holder.resized.connect(func() -> void: holder.pivot_offset = holder.size * 0.5)
	return holder


## Under THE END once it stops: thanks + Quit (desktop) or a web-friendly last line.
func _build_end_box() -> void:
	_end_box = VBoxContainer.new()
	_end_box.visible = false
	_end_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_end_box.add_theme_constant_override(&"separation", 18)
	_end_box.set_anchors_preset(PRESET_CENTER_BOTTOM)
	_end_box.grow_horizontal = GROW_DIRECTION_BOTH
	_end_box.grow_vertical = GROW_DIRECTION_BEGIN
	_end_box.offset_bottom = -70.0
	_end_box.custom_minimum_size.x = 560.0
	add_child(_end_box)
	var thanks := PanelContainer.new()
	thanks.add_theme_stylebox_override(&"panel", _style(PAPER, 4, 6, 14))
	var web := OS.has_feature("web")
	var text := "Thanks for playing! You can close this tab now." if web else "Thanks for playing!"
	thanks.add_child(_label(text, NAME_FONT, 26, INK, HORIZONTAL_ALIGNMENT_CENTER, false))
	thanks.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_end_box.add_child(thanks)
	if web:
		return
	var quit := Button.new()
	quit.name = "Quit"
	quit.text = "Quit"
	quit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	quit.custom_minimum_size = Vector2(180, 0)
	quit.add_theme_font_override(&"font", CAPTION_FONT)
	quit.add_theme_font_size_override(&"font_size", 30)
	quit.add_theme_color_override(&"font_color", INK)
	quit.add_theme_color_override(&"font_hover_color", INK)
	quit.add_theme_color_override(&"font_pressed_color", INK)
	quit.add_theme_color_override(&"font_focus_color", INK)
	quit.add_theme_stylebox_override(&"normal", _style(Color("#ff6b5b"), 4, 6, 10))
	quit.add_theme_stylebox_override(&"hover", _style(Color("#ff8a7d"), 4, 6, 10))
	quit.add_theme_stylebox_override(&"pressed", _style(Color("#e04535"), 4, 3, 10))
	quit.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	quit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	quit.pressed.connect(_quit)
	_end_box.add_child(quit)


func _label(text: String, font: Font, size_px: int, color: Color, align: HorizontalAlignment, wrap := true) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size_px)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label


## Comic panel style: flat fill, thick ink outline, solid offset shadow.
func _style(fill: Color, border: int, shadow: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = INK
	style.set_border_width_all(border)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(INK, 0.9)
	style.shadow_offset = Vector2(shadow, shadow)
	style.shadow_size = 1 if shadow > 0 else 0
	style.set_content_margin_all(margin)
	return style

extends Control
## Ending: the credits roll. Comic panels (paper, thick outline, offset shadow, yellow caption) scroll
## up over a halftone sky: the team, then every external asset and its licence (kept in step with
## game/CREDITS.md, its "Credits screen text"), then THE END. THE END stops in the middle of the
## screen, the narrator signs off and the end screen offers Quit (desktop only: a web page can't
## close itself, so on the web it just stays). Hold Space, Enter or the mouse button to fast-forward.
##
## To add a credit: add a line to the right section of `SECTIONS` (and to game/CREDITS.md).

## [caption, lines]. A line starting with "# " is drawn as a big name, the rest as small print.
const SECTIONS: Array = [
	["A GAME BY", [
		"# Vishesh Saraswat",
		"# Druhan Shah",
		"# Nandini Chakaravarthy",
		"# Kimaya Arora",
		"# Arnav Gupta",
	]],
	["3D MODELS", [
		"Low Poly 3D Office Set by VNB (Leo), vnbp.itch.io, CC BY 4.0",
		"PSX First Person Arms by Drillimpact, drillimpact.itch.io, CC0",
		"Screwdriver by CreativeTrio (Poly Pizza), CC0",
		"Spectacles by iPoly3D (Poly Pizza), CC0",
	]],
	["FONTS", [
		"Comic Neue by Craig Rozynski & Hrant Papazian, © 2014 The Comic Neue Project Authors, SIL OFL 1.1",
		"Comic Relief by Jeff Davis, © 2013 The Comic Relief Project Authors, SIL OFL 1.1",
		"Comic Shanns Mono, © 2018 Shannon Miwa, © 2023 Jesus Gonzalez, MIT License",
		"Tinos, Arimo, EB Garamond, Anton: © their Project Authors, SIL OFL 1.1",
		"Office Sans Jam, modified from Carlito (© 2013 The Carlito Project Authors), SIL OFL 1.1",
		"Almendra by Ana Sanfelippo, SIL OFL 1.1",
		"Jamdings: glyphs © 2022 The Noto Project Authors, SIL OFL 1.1",
		"Comic Sans MS is not used; it is licensed by Microsoft.",
		"Times New Roman, Arial, Helvetica, Calibri, Papyrus, Impact, Wingdings and Comic Sans are trademarks of their respective owners. None of those fonts are included.",
	]],
	["SOUNDS", [
		"400 Sounds Pack by Chequered Ink, ci.itch.io",
		"Interface Sounds by Kenney, kenney.nl, CC0",
		"From Freesound, all CC0: rolling chair by alpanaytekin; screwdriver by 16GPanskaToman_Kristian; bolt drop by zembacraftworks; panel clatter by ME_Studios_Official; electricity by NachtmahrTV; wire plug by preyk; zaps by michael_grinnell and elliott.klein; breaker by kyles; neon hum by Kinoton; \"Wrong Buzzer\" by KevinVG207",
	]],
	["ENGINE", [
		"Made with Godot Engine, godotengine.org/license",
	]],
	["SAFETY NOTICE", [
		"No lights were harmed in the making of this game.",
		"Several were inconvenienced.",
	]],
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
	_build_background()
	_roll = VBoxContainer.new()
	_roll.add_theme_constant_override(&"separation", 56)
	_roll.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_roll)
	_roll.add_child(_caption_only("MEANWHILE, IN THE CREDITS..."))
	for section: Array in SECTIONS:
		_roll.add_child(_panel(section[0], section[1]))
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
	Narrator.play(&"credits_end")
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
func _caption_only(text: String) -> Control:
	var holder := CenterContainer.new()
	var box := PanelContainer.new()
	box.add_theme_stylebox_override(&"panel", _style(CAPTION, 4, 6, 14))
	box.rotation_degrees = -2.0
	box.add_child(_label(text, CAPTION_FONT, 30, INK, HORIZONTAL_ALIGNMENT_CENTER, false))
	holder.add_child(box)
	return holder


## A panel: caption on the top edge, names or small print below.
func _panel(caption: String, lines: Array) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", _style(PAPER, 5, 9, 26))
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	panel.add_child(box)
	var head := PanelContainer.new()
	head.add_theme_stylebox_override(&"panel", _style(CAPTION, 3, 0, 8))
	head.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	head.add_child(_label(caption, CAPTION_FONT, 24, INK, HORIZONTAL_ALIGNMENT_LEFT, false))
	box.add_child(head)
	for line: String in lines:
		if line.begins_with("# "):
			box.add_child(_label(line.substr(2), NAME_FONT, 38, INK, HORIZONTAL_ALIGNMENT_CENTER))
		else:
			box.add_child(_label(line, BODY_FONT, 19, INK, HORIZONTAL_ALIGNMENT_LEFT))
	return panel


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

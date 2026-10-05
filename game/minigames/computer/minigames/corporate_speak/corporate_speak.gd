extends Minigame
## Fill-in-the-blank memo: pick the most corporate word for each blank. Every word carries its own
## points (written in the sentence, see CorporateSpeakConfig.sentences); on submit the total goes to
## the computer's score. Sentences and tunables live in corporate_speak_default.tres.

const BLANK_TEXT := "________"
const BEST_COLOR := Color(0.1, 0.55, 0.2)
const OK_COLOR := Color(0.75, 0.5, 0.05)
const BAD_COLOR := Color(0.8, 0.15, 0.1)
const ACTIVE_COLOR := Color(0.15, 0.35, 0.85)
## Fraction of the screen height the memo is centred on (above the middle, so it covers the text).
const CENTER_HEIGHT := 0.4

## Not repeated twice in a row.
static var _last_sentence := ""

var _segments: Array = [] ## String (plain text) or Blank, in sentence order.
var _blanks: Array[Blank] = []
var _active: Blank
var _center := Vector2.ZERO

@onready var sentence_flow: HFlowContainer = %Sentence
@onready var options_flow: HFlowContainer = %Options
@onready var result_label: Label = %Result
@onready var submit_button: Button = %Submit


class Blank:
	var options: Array[Dictionary] = [] ## {"word": String, "points": int}
	var chosen := -1
	var button: Button

	func word() -> String:
		return options[chosen].word if chosen >= 0 else ""

	func points() -> int:
		return options[chosen].points if chosen >= 0 else 0

	func best() -> int:
		var top: int = options[0].points
		for option in options:
			top = maxi(top, option.points)
		return top


## Splits a sentence into plain-text Strings and Arrays of {"word", "points"} options, one per {blank}.
static func parse(line: String) -> Array:
	var segments := []
	var cursor := 0
	for found in RegEx.create_from_string("\\{([^}]*)\\}").search_all(line):
		if found.get_start() > cursor:
			segments.append(line.substr(cursor, found.get_start() - cursor))
		var options: Array[Dictionary] = []
		for raw in found.get_string(1).split("|", false):
			var colon := raw.rfind(":")
			var word := raw.left(colon) if colon >= 0 else raw
			var points := raw.substr(colon + 1).strip_edges().to_int() if colon >= 0 else 0
			options.append({"word": word.strip_edges(), "points": points})
		if not options.is_empty():
			segments.append(options)
		cursor = found.get_end()
	if cursor < line.length():
		segments.append(line.substr(cursor))
	return segments


func _ready() -> void:
	submit_button.pressed.connect(_submit)


func begin() -> void:
	var cfg := config as CorporateSpeakConfig
	if cfg.sentences.is_empty():
		push_error("CorporateSpeak: no sentences in config")
		fail()
		return
	_build(parse(_pick_sentence(cfg.sentences)))
	submit_button.disabled = true
	result_label.text = ""
	_center = get_parent_area_size() * Vector2(0.5, CENTER_HEIGHT)
	resized.connect(_recenter)
	_recenter()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	if not _blanks.is_empty():
		_select_blank(_blanks[0])


func _pick_sentence(sentences: Array[String]) -> String:
	var pool := sentences.filter(func(s: String) -> bool: return s != _last_sentence)
	if pool.is_empty():
		pool = sentences
	_last_sentence = pool.pick_random()
	return _last_sentence


func _build(parsed: Array) -> void:
	var shuffle := (config as CorporateSpeakConfig).shuffle_options
	var token_regex := RegEx.create_from_string("\\s*\\S+\\s*")
	for segment in parsed:
		if segment is String:
			# One label per word (keeping its spaces) so the line wraps between words.
			for token in token_regex.search_all(segment):
				var label := Label.new()
				label.text = token.get_string()
				sentence_flow.add_child(label)
			_segments.append(segment)
			continue
		var blank := Blank.new()
		blank.options = segment
		if shuffle:
			blank.options.shuffle()
		blank.button = Button.new()
		blank.button.text = BLANK_TEXT
		blank.button.flat = true
		blank.button.theme_type_variation = &"BlankButton"
		blank.button.focus_mode = Control.FOCUS_NONE
		blank.button.pressed.connect(_select_blank.bind(blank))
		sentence_flow.add_child(blank.button)
		_blanks.append(blank)
		_segments.append(blank)


func _select_blank(blank: Blank) -> void:
	if _active:
		_active.button.remove_theme_color_override("font_color")
	_active = blank
	blank.button.add_theme_color_override("font_color", ACTIVE_COLOR)
	for child in options_flow.get_children():
		child.queue_free()
	for i in blank.options.size():
		var option := Button.new()
		option.text = blank.options[i].word
		option.focus_mode = Control.FOCUS_NONE
		option.pressed.connect(_choose.bind(blank, i))
		options_flow.add_child(option)


func _choose(blank: Blank, index: int) -> void:
	blank.chosen = index
	blank.button.text = blank.word()
	var cfg := config as CorporateSpeakConfig
	if cfg.choose_sfx:
		Audio.play_sfx(cfg.choose_sfx)
	var unfilled := _blanks.filter(func(b: Blank) -> bool: return b.chosen < 0)
	submit_button.disabled = not unfilled.is_empty()
	if unfilled:
		_select_blank(unfilled[0])


func _submit() -> void:
	var total := 0
	for blank in _blanks:
		var points := blank.points()
		total += points
		var color := BEST_COLOR if points == blank.best() else (BAD_COLOR if points <= 0 else OK_COLOR)
		blank.button.text = "%s (%+d)" % [blank.word(), points]
		blank.button.add_theme_color_override("font_color", color)
		blank.button.add_theme_color_override("font_disabled_color", color)
		blank.button.disabled = true
	for child in options_flow.get_children():
		child.queue_free()
	submit_button.disabled = true
	reset_size.call_deferred() # shrink back now the options row is empty
	result_label.text = "Corporate alignment: %+d" % total
	var cfg := config as CorporateSpeakConfig
	if cfg.submit_sfx:
		Audio.play_sfx(cfg.submit_sfx)
	if computer:
		computer.add_score(total)
		if cfg.append_to_document:
			var separator := " " if computer.buffer and not computer.buffer.right(1) in [" ", "\n", "\t"] else ""
			computer.buffer += separator + _filled_sentence()
	# Tween (not a SceneTreeTimer) so it dies with the memo if the computer closes first.
	create_tween().tween_interval(cfg.result_display_time).finished.connect(complete)


func _filled_sentence() -> String:
	var text := ""
	for segment in _segments:
		text += segment if segment is String else (segment as Blank).word()
	return text


## Keeps the memo centred while its containers resize to fit the sentence.
func _recenter() -> void:
	position = _center - size / 2.0

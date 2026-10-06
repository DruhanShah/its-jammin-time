extends Node
## Autoload "Narrator": plays narrator cues with subtitles. A new line interrupts the current one.
## Process mode Always (narrator.tscn): lines and subtitles carry on while the tree is paused.
## Long subtitles are split into short chunks shown one after another (Netflix/BBC style): each chunk
## fits on one line at the current width where possible (two at most), breaks go at sentence ends first,
## then clause punctuation (, ; : dashes, mid-sentence "..."), then before a conjunction, never mid-word,
## and very short chunks are avoided. Writers can force a break with "|" or a newline in the cue's text.

signal line_started(cue_id: StringName)
signal line_finished(cue_id: StringName)

const CUE_DIR := "res://narration/"
## Subtitle-only cues (no audio) stay up for their length at this reading speed, but at least MIN_READ_TIME.
## 15 chars/s sits under Netflix's 17 chars/s adult limit, since the player is also walking around.
const READ_CHARS_PER_SECOND := 15.0
const MIN_READ_TIME := 2.0
## Each chunk of a subtitle-only line stays up at least this long.
const MIN_CHUNK_TIME := 1.2
## Chunks shorter than this are avoided (no "Ah." on its own).
const MIN_CHUNK_CHARS := 12
## Costs the splitter minimises: per chunk, per break by quality (sentence, clause, conjunction, any
## space), for a chunk that is too short, needs two lines or more than two, or holds a sentence end but
## starts or stops mid-sentence ("...for those. Sadly,"). BALANCE_COST * lines^2 evens chunk lengths out.
const CHUNK_COST := 10.0
const BREAK_COSTS: Array[float] = [0.0, 15.0, 35.0, 120.0]
const SHORT_COST := 40.0
const TWO_LINES_COST := 100.0
const OVERFLOW_COST := 1000.0
const MIXED_COST := 50.0
const BALANCE_COST := 20.0
## Voiced lines: a chunk the voice would flash past quicker than this joins a neighbour (if that fits two lines).
const MIN_VOICED_CHUNK_TIME := 1.0
const FORCED_BREAK := "|"
const CONJUNCTIONS: PackedStringArray = [
	"and", "but", "or", "so", "because", "which", "who", "when", "while", "if", "until", "unless",
	"though", "although", "where", "then",
]

var current_cue := &""
var _played: Dictionary[StringName, bool] = {}
var _line_scene_id := 0 ## Instance ID of the scene that was current when the line started.
var _chunks := PackedStringArray()
var _chunk_times := PackedFloat32Array() ## Seconds each chunk stays up (the last one is unused for voiced lines).
var _chunk_index := 0

@onready var voice: AudioStreamPlayer = $Voice
@onready var read_timer: Timer = $ReadTimer
@onready var chunk_timer: Timer = $ChunkTimer
@onready var subtitle_label: Label = $Subtitles/Label


func _ready() -> void:
	voice.finished.connect(_on_line_finished)
	read_timer.timeout.connect(_on_line_finished)
	chunk_timer.timeout.connect(_on_chunk_timeout)
	get_tree().scene_changed.connect(_on_scene_changed)
	subtitle_label.hide()


func play(cue_id: StringName) -> void:
	var path := CUE_DIR + cue_id + ".tres"
	if not ResourceLoader.exists(path):
		push_error("Narrator cue not found: " + path)
		return
	var cue: NarratorCue = load(path)
	if cue.stream == null and cue.subtitle == "":
		push_error("Narrator cue has no audio or subtitle: " + path)
		return
	if cue.once and _played.has(cue_id):
		return
	_played[cue_id] = true
	if current_cue:
		line_finished.emit(current_cue)
	current_cue = cue_id
	_line_scene_id = get_tree().current_scene.get_instance_id() if get_tree().current_scene else 0
	voice.stop()
	read_timer.stop()
	chunk_timer.stop()
	_chunks = split_subtitle(cue.subtitle)
	var length := cue.stream.get_length() if cue.stream else 0.0
	if length > 0.0:
		_chunks = _merge_fast_chunks(_chunks, length)
	_chunk_times = _time_chunks(_chunks, length)
	if cue.stream:
		voice.stream = cue.stream
		voice.play()
	else:
		var total := 0.0
		for time in _chunk_times:
			total += time
		read_timer.start(total)
	_show_chunk(0)
	line_started.emit(cue_id)


func is_speaking() -> bool:
	return voice.playing or not read_timer.is_stopped()


## Cuts the current line short and hides its subtitle.
func stop() -> void:
	if current_cue:
		voice.stop()
		read_timer.stop()
		_on_line_finished()


## Splits a subtitle into the chunks shown one after another (see the top of this script).
func split_subtitle(text: String) -> PackedStringArray:
	var chunks := PackedStringArray()
	for part in text.replace("\n", FORCED_BREAK).split(FORCED_BREAK, false):
		var piece := " ".join(part.split(" ", false)) # Collapse runs of spaces.
		if piece != "":
			chunks.append_array(_split_piece(piece))
	return chunks


## Picks the cheapest set of breaks (dynamic programming over the spaces, see the costs above).
func _split_piece(text: String) -> PackedStringArray:
	var cuts := PackedInt32Array([-1]) # Spaces a chunk can end at, plus both ends of the text.
	var tiers := PackedInt32Array([0])
	for i in text.length():
		if text[i] == " ":
			cuts.append(i)
			tiers.append(_break_tier(text, i))
	cuts.append(text.length())
	tiers.append(0)
	var best := PackedFloat32Array([0.0])
	var from := PackedInt32Array([0])
	for b in range(1, cuts.size()):
		best.append(INF)
		from.append(b - 1)
		var sentence_inside := false
		for a in range(b - 1, -1, -1):
			if a < b - 1 and tiers[a + 1] == 0:
				sentence_inside = true
			var lines := _line_count(text.substr(cuts[a] + 1, cuts[b] - cuts[a] - 1))
			if lines > 2.0 and a < b - 1:
				break # Longer chunks only get worse.
			var cost := best[a] + CHUNK_COST + BALANCE_COST * lines * lines
			if b < cuts.size() - 1:
				cost += BREAK_COSTS[tiers[b]]
			if cuts[b] - cuts[a] - 1 < MIN_CHUNK_CHARS:
				cost += SHORT_COST
			if lines > 2.0:
				cost += OVERFLOW_COST
			elif lines > 1.0:
				cost += TWO_LINES_COST
			if sentence_inside and (tiers[a] != 0 or tiers[b] != 0):
				cost += MIXED_COST
			if cost < best[b]:
				best[b] = cost
				from[b] = a
	var chunks := PackedStringArray()
	var last := cuts.size() - 1
	while last > 0:
		chunks.insert(0, text.substr(cuts[from[last]] + 1, cuts[last] - cuts[from[last]] - 1))
		last = from[last]
	return chunks


## Voiced lines: joins chunks the voice would rush past (see MIN_VOICED_CHUNK_TIME) to a shorter neighbour.
func _merge_fast_chunks(chunks: PackedStringArray, audio_length: float) -> PackedStringArray:
	var merged := chunks.duplicate()
	while merged.size() > 1:
		var times := _time_chunks(merged, audio_length)
		var fastest := 0
		for i in merged.size():
			if times[i] < times[fastest]:
				fastest = i
		if times[fastest] >= MIN_VOICED_CHUNK_TIME:
			break
		var first := fastest
		if fastest == merged.size() - 1 or (fastest > 0 and merged[fastest - 1].length() < merged[fastest + 1].length()):
			first = fastest - 1
		var joined := merged[first] + " " + merged[first + 1]
		if _line_count(joined) > 2.0:
			break
		merged[first] = joined
		merged.remove_at(first + 1)
	return merged


## How good a break the space at index i is (lower is better).
func _break_tier(text: String, i: int) -> int:
	var before := text[i - 1]
	if before in ")\"'" and i >= 2:
		before = text[i - 2]
	var next := text[i + 1]
	var mid_sentence := next != next.to_upper() # The next word starts lowercase.
	if before in ".!?…":
		return 1 if mid_sentence else 0
	if before in ",;:—–" or (before == "-" and i >= 2 and text[i - 2] == " "):
		return 1
	if text.substr(i + 1).get_slice(" ", 0).to_lower() in CONJUNCTIONS:
		return 2
	return 3


## How many label lines the text needs at the subtitle's current width (fractional).
func _line_count(text: String) -> float:
	var width := subtitle_label.size.x - 2.0 * subtitle_label.get_theme_constant(&"outline_size")
	var font := subtitle_label.get_theme_font(&"font")
	var font_size := subtitle_label.get_theme_font_size(&"font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x / maxf(width, 1.0)


## Voiced lines share the audio length by character count; subtitle-only ones get a reading time each.
func _time_chunks(chunks: PackedStringArray, audio_length: float) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	var total_chars := 0
	for chunk in chunks:
		total_chars += chunk.length()
	for chunk in chunks:
		if audio_length > 0.0:
			times.append(audio_length * chunk.length() / total_chars)
		else:
			times.append(maxf(MIN_CHUNK_TIME, chunk.length() / READ_CHARS_PER_SECOND))
	if audio_length <= 0.0 and not times.is_empty():
		var total := 0.0
		for time in times:
			total += time
		if total < MIN_READ_TIME:
			times[times.size() - 1] += MIN_READ_TIME - total
	return times


func _show_chunk(index: int) -> void:
	_chunk_index = index
	subtitle_label.visible = index < _chunks.size()
	if not subtitle_label.visible:
		return
	subtitle_label.text = _chunks[index]
	if index < _chunks.size() - 1:
		chunk_timer.start(_chunk_times[index])


func _on_chunk_timeout() -> void:
	_show_chunk(_chunk_index + 1)


func _on_scene_changed() -> void:
	# Lines belong to the scene they were cued in; one cued by the new scene's _ready() keeps playing.
	if get_tree().current_scene.get_instance_id() != _line_scene_id:
		stop()


func _on_line_finished() -> void:
	chunk_timer.stop()
	subtitle_label.hide()
	_chunks.clear()
	var cue_id := current_cue
	current_cue = &""
	line_finished.emit(cue_id)

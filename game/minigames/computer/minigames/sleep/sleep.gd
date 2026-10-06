extends Minigame
## Sleep: the screen dims and the bank balance drains until you wake up.
## Started by the Sleep button on the computer screen (Computer.sleep()), also in the middle of another
## minigame: it lies on top, freezes every other minigame (no processing, timers, tweens or input,
## also ones spawned while asleep) and swallows all typing; Wake Up unfreezes them where they were.
## It is not part of the event manager's queue, so waking up never counts as beating a story step.

var _cfg: SleepConfig
var _carry := 0.0 ## fractional money not taken off yet
var _frozen: Dictionary[Node, ProcessMode] = {} ## other minigames -> their process mode before sleeping

@onready var dim: ColorRect = $Dim
@onready var zzz: Label = %Zzz
@onready var balance: Label = %Balance
@onready var wake: Button = %Wake


func begin() -> void:
	_cfg = config as SleepConfig
	wake.pressed.connect(_wake_up)
	for child in get_parent().get_children():
		_freeze(child)
	get_parent().child_entered_tree.connect(_freeze)
	dim.color.a = 0.0
	create_tween().tween_property(dim, "color:a", _cfg.dim_alpha, _cfg.fade_seconds)
	var bob := create_tween().set_loops()
	bob.tween_property(zzz, "position:y", -10.0, 1.2).as_relative().set_trans(Tween.TRANS_SINE)
	bob.tween_property(zzz, "position:y", 10.0, 1.2).as_relative().set_trans(Tween.TRANS_SINE)
	if _cfg.fall_asleep_cue:
		Narrator.play(_cfg.fall_asleep_cue)
	_refresh()


func cleanup() -> void:
	if get_parent() and get_parent().child_entered_tree.is_connected(_freeze):
		get_parent().child_entered_tree.disconnect(_freeze)
	for node in _frozen:
		if is_instance_valid(node):
			node.process_mode = _frozen[node]
	_frozen.clear()


func _wake_up() -> void:
	if _cfg.wake_cue:
		Narrator.play(_cfg.wake_cue)
	complete()


func _freeze(node: Node) -> void:
	if node == self or node in _frozen:
		return
	_frozen[node] = node.process_mode
	node.process_mode = Node.PROCESS_MODE_DISABLED
	move_to_front.call_deferred() # Stay on top of minigames spawned while asleep.


func _process(delta: float) -> void:
	_carry += _cfg.drain_per_second * delta
	var whole := int(_carry)
	if whole > 0:
		GameState.bank_balance -= whole
		_carry -= whole
		_refresh()
		if computer:
			computer.bank_changed.emit(GameState.bank_balance)


## No typing at the computer while asleep (_input runs before the document, minigames and text boxes).
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	balance.text = "Bank balance: %s" % Computer.bank_text()
	balance.add_theme_color_override("font_color", Color(1, 0.42, 0.36) if GameState.bank_balance < 0 else Color(1, 0.82, 0.25))

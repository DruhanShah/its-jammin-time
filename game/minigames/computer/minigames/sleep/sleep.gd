extends Minigame
## Sleep: the screen dims and the bank balance drains until you wake up.
## Started by the Sleep button on the computer screen (Computer.sleep()). It is not part of the
## event manager's queue, so waking up never counts as beating a story step.

var _cfg: SleepConfig
var _carry := 0.0 ## fractional money not taken off yet

@onready var dim: ColorRect = $Dim
@onready var balance: Label = %Balance
@onready var wake: Button = %Wake


func begin() -> void:
	_cfg = config as SleepConfig
	wake.pressed.connect(complete)
	dim.color.a = 0.0
	create_tween().tween_property(dim, "color:a", _cfg.dim_alpha, _cfg.fade_seconds)
	wake.grab_focus.call_deferred()
	_refresh()


func _process(delta: float) -> void:
	_carry += _cfg.drain_per_second * delta
	var whole := int(_carry)
	if whole > 0:
		GameState.bank_balance -= whole
		_carry -= whole
		_refresh()
		if computer:
			computer.bank_changed.emit(GameState.bank_balance)


## No typing at the computer while asleep.
func _unhandled_key_input(_e: InputEvent) -> void:
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	balance.text = "Bank balance: %s" % Computer.bank_text()
	balance.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3) if GameState.bank_balance < 0 else Color(0.75, 0.71, 0.43))

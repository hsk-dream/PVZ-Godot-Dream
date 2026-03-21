extends Control
class_name CoinBankLabel

## 是否自动隐藏
@export var auto_hide := true
@onready var label_coin_value: Label = $TextureRect/LabelCoinValue
@onready var timer_auto_hide: Timer = $TimerAutoHide
@onready var marker_2d_coin_target: Marker2D = $Marker2DCoinTarget

func _ready() -> void:
	Global.global_game_state.coin_value_changed.connect(_on_coin_value_changed)
	update_label()
	EventBus.subscribe("on_create_coin", _on_create_coin)

func _on_create_coin():
	update_label()

func _on_coin_value_changed(_new_value: int) -> void:
	update_label()


func update_label() -> void:
	visible = true
	label_coin_value.text = "$" + GlobalUtils.format_number_with_commas(Global.global_game_state.coin_value)
	if auto_hide:
		timer_auto_hide.start()


func _on_timer_auto_hide_timeout() -> void:
	visible = false

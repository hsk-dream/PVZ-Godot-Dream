extends Control
class_name CoinBankLabel

## 是否自动隐藏
@export var auto_hide := true
@onready var label_coin_value: Label = $TextureRect/LabelCoinValue
@onready var timer_auto_hide: Timer = $TimerAutoHide
@onready var marker_2d_coin_target: Marker2D = $Marker2DCoinTarget

func _ready() -> void:
	update_label()


func update_label():
	visible = true
	label_coin_value.text = "$" + GlobalUtils.format_number_with_commas(Global.global_game_state.coin_value)
	if auto_hide:
		if is_instance_valid(Global.main_game) and Global.main_game.main_game_progress == MainGameManager.E_MainGameProgress.RE_CHOOSE_CARD:
			visible = false
		else:
			timer_auto_hide.start()


func _on_timer_auto_hide_timeout() -> void:
	visible = false

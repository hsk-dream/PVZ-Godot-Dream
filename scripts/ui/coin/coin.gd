extends Node2D
class_name Coin

@export var coin_value := 50

@onready var anim_lib: AnimationPlayer = $AnimLib
@onready var button: TextureButton = $Button
## 金币存在时间
@export var coin_exist_time :float = 10

## 是否可以动画
@export var is_anim := false:
	set(value):
		is_anim = value
		if value:
			anim_lib.play("ALL_ANIMS")
		else:
			anim_lib.seek(0.0, true)  # 跳到第0秒（第一帧），并立即更新动画
			anim_lib.stop(true)

var coin_target_position := Vector2(0,0)

#抛物线
@export var gravity := -800.0         # 模拟重力
@export var duration := 1.0           # 飞行时间
@export var peak_height := 70.0      # 抛物线的最大高度（正值）
var tween: Tween = null

## 是否被获取
var is_get:bool = false



func _ready():
	## 信号连接
	button.pressed.connect(_on_button_pressed)
	if is_instance_valid(Global.main_game) and Global.main_game.game_para.is_hammer:
		button.mouse_entered.connect(Global.main_game.mouse_appear_have_hammer)
		button.mouse_exited.connect(Global.main_game.mouse_disappear_have_hammer)

	await get_tree().create_timer(coin_exist_time, false).timeout
	fade_and_delete()


func fade_and_delete():
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)  # 1秒内 alpha 从当前变到 0
	fade_tween.tween_callback(Callable(self, "queue_free"))  # 动画完成后删除自身


func launch(relative_target: Vector2):
	is_anim = false
	var start_pos: Vector2 = position
	var end_pos: Vector2 = start_pos + relative_target

	tween = create_tween()
	tween.set_parallel()
	# 水平 x：线性插值
	tween.tween_property(self, "position:x", end_pos.x, duration)
	# 垂直 y：使用函数插值构建抛物线
	tween.tween_method(
		func(t):
			# t ∈ [0, 1]，计算当前 y
			var y = lerp(start_pos.y, end_pos.y, t) - 4 * peak_height * t * (1 - t)
			position.y = y,
		0.0,
		1.0,
		duration
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	tween = null
	is_anim = true
	## 如果开启自动收集金币
	if Global.config_service.auto_collect_coin:
		button.pressed.emit()

func _on_interrupt_triggered():
	# 外部中断调用
	if tween:
		tween.kill()
		tween = null

## 点击金币
func _on_button_pressed() -> void:
	if is_get:
		return
	is_get = true
	SoundManager.play_other_SFX("coin")
	button.queue_free()
	##打断抛物线
	_on_interrupt_triggered()
	is_anim = false
	## 如果当前场景有金币值的label
	if Global.coin_value_label and is_instance_valid(Global.coin_value_label):
		coin_target_position = Global.coin_value_label.marker_2d_coin_target.global_position


	var click_tween:Tween = create_tween()
	click_tween.tween_property(self, "global_position", coin_target_position, 0.5)
	await click_tween.finished
	Global.global_game_state.coin_value += coin_value
	click_tween = create_tween()
	click_tween.set_parallel()
	click_tween.tween_property(self, "modulate:a", 0, 0.5)
	click_tween.tween_property(self, "scale", Vector2(0.5,0.5), 0.5)

	await click_tween.finished
	queue_free()


## 被吸金石吸引铁器
func be_attract_gold_magnet(target_global_pos:Vector2):
	if is_get:
		return
	is_get = true
	##打断抛物线
	_on_interrupt_triggered()

	var be_attract_tween:Tween = create_tween()
	be_attract_tween.tween_property(self, "global_position", target_global_pos, 0.5)
	await be_attract_tween.finished
	Global.global_game_state.coin_value += coin_value
	be_attract_tween = create_tween()
	be_attract_tween.set_parallel()
	be_attract_tween.tween_property(self, "modulate:a", 0, 0.5)
	be_attract_tween.tween_property(self, "scale", Vector2(0.5,0.5), 0.5)

	await be_attract_tween.finished
	queue_free()

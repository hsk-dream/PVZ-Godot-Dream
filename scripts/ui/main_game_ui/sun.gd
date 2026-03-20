extends Node2D
class_name Sun

@export var sun_value := 25

## 阳光存在时间
@export var exist_time:float = 10.0
var collected := false  # 是否已被点击收集
## 生产阳光移动的tween
var spawn_sun_tween:Tween

func _ready() -> void:
	_sun_scale(sun_value)
	## 启动一个10秒定时器
	await get_tree().create_timer(exist_time, false).timeout

	# 如果还没被点击收集，自动销毁
	if not collected and is_instance_valid(self):
		_start_fade_out()

func init_sun(curr_sun_value:int, pos:Vector2):
	sun_value = curr_sun_value
	position = pos

func _sun_scale(new_sun_value:int):
	var new_scale = new_sun_value/25.0
	scale = Vector2(new_scale,new_scale)


func _on_button_pressed() -> void:
	if spawn_sun_tween:
		spawn_sun_tween.kill()

	if collected:
		return  # 防止重复点击

	collected = true  # 设置已被收集
	var target_position = Vector2()
	SoundManager.play_other_SFX("points")
	if is_instance_valid(Global.main_game):
		if is_instance_valid(Global.main_game.marker_2d_sun_target):
			## 出战卡槽在canvaslayer中，位置和摄像头位置有偏移
			target_position = Global.main_game.marker_2d_sun_target.global_position + Global.main_game.camera_2d.global_position
			#print(Global.main_game.marker_2d_sun_target.get_canvas_layer_node().get_final_transform())
		else:
			target_position = Global.main_game.marker_2d_sun_target_default.global_position

		EventBus.push_event("add_sun_value", [sun_value])

	var tween:Tween = get_tree().create_tween()
	# 将节点从当前位置移动到(100, 200)，耗时0.5秒
	tween.tween_property(self, "global_position", target_position, 0.3).set_ease(Tween.EASE_OUT)
	$Button.queue_free()
	await tween.finished
	## 到达位置，变透明
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(self, "modulate:a", 0, 0.5)
	await tween.finished
	queue_free()


func _start_fade_out() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)  # 🌫️ 1秒淡出
	tween.finished.connect(func():
		if not collected and is_instance_valid(self):
			self.queue_free()
	)

func on_sun_tween_finished():
	if Global.config_service.auto_collect_sun:
		_on_button_pressed()

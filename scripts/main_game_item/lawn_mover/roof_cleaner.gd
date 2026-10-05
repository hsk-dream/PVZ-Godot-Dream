extends LawnMover
class_name RoofCleaner

## 屋顶斜坡 移动方向y值修正,移动时,对应y方向的修正,
var move_dir_y_correct_slope:Vector2 = Vector2.ZERO
var move_x:float

func _ready() -> void:
	super()
	if is_instance_valid(Global.main_game.main_game_slope):
		#await get_tree().process_frame
		## 获取对应位置的斜面y相对位置
		var slope_y_first = Global.main_game.main_game_slope.get_all_slope_y(global_position.x)
		position.y += slope_y_first
		print("x位置：", global_position.x, "修正位置：", slope_y_first)


func _process(delta: float) -> void:
	if is_moving:
		move_x = move_speed * delta
		position.x += move_x

		## 斜面移动修正
		if move_dir_y_correct_slope != Vector2.ZERO:
			position.y += move_x / move_dir_y_correct_slope.x * move_dir_y_correct_slope.y

		if not screen_rect.has_point(global_position):
			queue_free()


## 更新移动方向修正(斜面时使用)
func update_move_dir_y_correct(curr_move_dir_y_correct_slope:Vector2):
	#print("更新移动方向:", move_dir)
	self.move_dir_y_correct_slope = curr_move_dir_y_correct_slope


## 启动小推车
func _start_mower():
	# 覆盖基类的启动入口也要拦截销毁当帧的延迟信号。
	if is_destroyed or is_queued_for_deletion():
		return
	is_moving = true
	animation_player.play("RoofCleaner")
	SoundManager.play_other_SFX("lawnmower")
	_mower_run_all_zombie_on_start()

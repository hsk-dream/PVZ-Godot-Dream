extends Node2D
class_name ZombieDropBase

var is_active := false
var drop_body : Node2D

@export var ground_y := 0.0 	# 地面位置
var landed := false 	# 用于判断是否已经着地
var gravity := 500.0	# 重力速度

@export var x_v : float			# x的速度
@export var rotation_speed : float	# 旋转速度
var velocity : Vector2

@export var bounce_damping := 0.5  # 弹跳衰减系数（0.5 表示每次弹跳速度减半）
var min_bounce_speed := 30.0  # 小于这个速度就不再反弹
var shake_intensity := 5.0  # 初始震动强度
var min_rotation_speed := 0.2  # 最小旋转速度

var is_swimming := false
var zombie: Zombie000Base

func _ready() -> void:
	if owner is Zombie000Base:
		zombie = owner

func _physics_process(delta: float) -> void:
	if is_active:
		# 应用重力
		velocity.y += gravity * delta
		drop_body.position += velocity * delta
		drop_body.rotation += rotation_speed * delta

		# 逐渐减小旋转速度
		if abs(rotation_speed) >= min_rotation_speed:
			if rotation_speed >= 0:
				rotation_speed -= 0.1 * delta  # 每帧减少一定的旋转速度，逐渐变慢
			else :
				rotation_speed += 0.1 * delta  # 每帧减少一定的旋转速度，逐渐变慢

		# 检查是否到达地面
		if drop_body.position.y >= ground_y:
			if is_swimming:
				# 在水里直接停止移动
				velocity = Vector2.ZERO
				rotation_speed = 0.0
				landed = true
				fade_and_delete()

			drop_body.position.y = ground_y

			if abs(velocity.y) > min_bounce_speed:
				velocity.y = -velocity.y * bounce_damping  # 反弹，速度减弱

				# 弹跳时保留震动效果
				shake_intensity = max(0, shake_intensity - 0.2)  # 随着弹跳减少震动强度
			else:
				# 最后一轮反弹后停止移动
				velocity = Vector2.ZERO
				rotation_speed = 0.0
				landed = true
				fade_and_delete()


func acitvate_it(control_x:float = 0):
	drop_body = get_child(0)
	if control_x != 0:
		velocity = Vector2(control_x, velocity.y)
	is_active = true
	## 如果僵尸在水里
	if zombie.is_swimming:
		ground_y = 200
		is_swimming = true


	var zombie_lane :ZombieRow= Global.main_game.zombie_manager.all_zombie_rows[zombie.lane]
	reparent(zombie_lane)

	## 从地下出现的僵尸修改其陆地位置
	if zombie.is_body_up_from_ground:
		ground_y = zombie_lane.zombie_create_position.global_position.y - global_position.y
		#var drop_body_glo_pos:Vector2 = drop_body.global_position
		#global_position.y = zombie_lane.zombie_create_position.global_position.y
		#drop_body.global_position = drop_body_glo_pos



## 被小推车推倒时
func acitvate_it_on_ground(global_pos_x:float):
	drop_body = get_child(0)
	drop_body.global_position.x = global_pos_x
	drop_body.position.y = 10
	velocity = Vector2(randf_range(-50, -30),-500)
	is_active = true
	var zombie_lane :ZombieRow= Global.main_game.zombie_manager.all_zombie_rows[zombie.lane]
	reparent(zombie_lane)



func fade_and_delete():
	var tween = create_tween()
	tween.tween_property(drop_body, "modulate:a", 0.0, 1.0)  # 1秒内 alpha 从当前变到 0
	tween.tween_callback(Callable(self, "queue_free"))  # 动画完成后删除自身

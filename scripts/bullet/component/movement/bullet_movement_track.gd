extends BulletMovementBase
class_name BulletMovementTrack
## 子弹移动组件 追踪

@onready var body: Node2D = $"../Body"


#region 贝塞尔曲线相关参数 原始目标每帧更新 和 被弹开后弹开时更新一次
## 子弹移动的总时间(控制点到起点和终点距离和/速度)
var all_time:float

## 贝塞尔曲线当前时间
var curr_time = 0.0
## 开始时全局位置
var start_global_pos:Vector2
## 贝塞尔曲线的控制点1
var start_control_point: Vector2
## 贝塞尔曲线控制点2
var second_control_point: Vector2
## 终点
"""
敌人每帧更新 位置 = 敌人位置+修正偏移(enemy_pos_corr_value，向上移动帧数)，敌人死亡时位置不变
被弹开时 更新一次
"""
var end_global_pos:Vector2
#endregion

## 下一帧的目标点
var next_point:Vector2
## 最终位置修正值,目标位置为角色位置+偏移
@export var target_pos_corr_value:Vector2 = Vector2(0, -40)
## 第一修正点的位置 确定时间 按当前速度移动的秒数,由于每帧更新方向,更新频繁,因此改变方向非常快
@export var first_point_time:float = 10

## 当前目标是否为鼠标
var is_mouse:=false

## 重置追踪移动组件,敌人死亡时，若没有敌人，给鼠标的位置
func reset_track_movement(end_glo_pos:Vector2, is_new_target:=false, is_mouse_new:=false):
	if is_mouse_new:
		end_global_pos = end_glo_pos
		if not is_mouse:
			is_mouse = true
	else:
		if is_mouse:
			is_mouse = false
		end_global_pos = end_glo_pos + target_pos_corr_value
		if is_new_target:
			curr_time = 0


func physics_process_bullet_move(delta: float) -> bool:
	## 如果敌人死亡或敌人不存在
	set_next_point(delta)
	body.look_at(next_point)
	bullet.global_position = bullet.global_position.move_toward(next_point, bullet.speed * delta)
	return true

func set_next_point(delta):
	curr_time += delta
	var distance = bullet.global_position.distance_to(end_global_pos)
	all_time = max(distance / bullet.speed, 0.0001)

	var t = min(curr_time / all_time, 1)
	if is_mouse:
		t = 0.8
	start_control_point = bullet.direction * bullet.speed * first_point_time + bullet.global_position

	next_point = bullet.global_position.bezier_interpolate(start_control_point, end_global_pos, end_global_pos, t)
	bullet.direction = (next_point - bullet.global_position).normalized()
	if is_mouse:
		var jitter := deg_to_rad(5.0)
		bullet.direction = bullet.direction.rotated(randf_range(-jitter, jitter)).normalized()
	## 将下一点位置设置为当前方向的100像素距离的点
	next_point = bullet.global_position + bullet.direction * 100

	#prints("子弹方向:", direction, "速度:", speed)
	#prints("当前全局位置", global_position, "第一控制点", start_control_point)

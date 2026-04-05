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
## 贝塞尔曲线计算的下一个点
var bezier_next_point:Vector2
## 贝塞尔曲线计算的时间
var bezier_t:float
#endregion

## 下一帧的目标点
var next_point:Vector2
## 最终位置修正值,目标位置为角色位置+偏移
@export var target_pos_corr_value:Vector2 = Vector2(0, -40)
## 第一修正点的位置 确定时间 按当前速度移动的秒数,由于每帧更新方向,更新频繁,因此改变方向非常快
@export var first_point_time:float = 10
## 子弹无目标时减速系数
@export_range(0, 1, 0.1, "子弹无目标时减速系数") var bullet_speed_r_target_null = 0.2
## 当前子弹速度系数
var curr_bullet_speed_r:float = 1.0


## 当前目标是否为鼠标
var curr_target_type :E_CurrTargetType = E_CurrTargetType.Null
enum E_CurrTargetType{
	Enemy,	## 敌人
	Mouse,	## 鼠标， no 敌人 and 开启跟随鼠标
	Null,	## 无, no 敌人 and no 开启跟随鼠标
}


## 重置追踪移动组件,敌人死亡时，若没有敌人，给鼠标的位置
## [is_enemy:Bool]: 是否有敌人
## [is_new_target:Bool]: 是否为更新敌人目标
## [end_glo_pos:Vector2]: 敌人位置
func reset_track_movement(is_enemy:=false, is_new_target:=false, end_glo_pos:Vector2=Vector2.ZERO):
	## 如果当前有敌人
	if is_enemy:
		curr_target_type = E_CurrTargetType.Enemy
		curr_bullet_speed_r = 1
		end_global_pos = end_glo_pos + target_pos_corr_value
		## 如果是新敌人，更新当前贝塞尔曲线时间
		if is_new_target:
			curr_time = 0
	## 如果没有敌人
	else:
		## 设置追踪鼠标
		if Global.config_service.track_bullet_mouse:
			curr_bullet_speed_r = 1
			curr_target_type = E_CurrTargetType.Mouse
			end_global_pos = get_global_mouse_position()
		else:
			curr_target_type = E_CurrTargetType.Null
			curr_bullet_speed_r = bullet_speed_r_target_null

## 根据下一个点，决定方向，按速度移动
func physics_process_bullet_move(delta: float) -> bool:
	## 如果敌人死亡或敌人不存在
	set_next_point(delta)
	body.look_at(next_point)
	bullet.global_position = bullet.global_position.move_toward(next_point, bullet.speed * delta * curr_bullet_speed_r)
	return true

func set_next_point(delta):
	## 计算贝塞尔曲线 时间 第一控制点
	match curr_target_type:
		E_CurrTargetType.Enemy:
			## 计算当前时间，子弹后半段 基本全为1
			curr_time += delta
			var distance = bullet.global_position.distance_to(end_global_pos)
			all_time = max(distance / bullet.speed, 0.0001)
			bezier_t = min(curr_time / all_time, 1)

			## 根据贝塞尔曲线计算下一点和子弹方向
			start_control_point = bullet.direction * bullet.speed * first_point_time + bullet.global_position
			bezier_next_point = bullet.global_position.bezier_interpolate(start_control_point, end_global_pos, end_global_pos, bezier_t)
			bullet.direction = (bezier_next_point - bullet.global_position).normalized()

		E_CurrTargetType.Mouse:
			bezier_t = 0.8

			## 根据贝塞尔曲线计算下一点和子弹方向
			start_control_point = bullet.direction * bullet.speed * first_point_time + bullet.global_position
			bezier_next_point = bullet.global_position.bezier_interpolate(start_control_point, end_global_pos, end_global_pos, bezier_t)
			bullet.direction = (bezier_next_point - bullet.global_position).normalized()

			## 鼠标有方向偏移，避免子弹重叠在一起
			var jitter := deg_to_rad(5.0)
			bullet.direction = bullet.direction.rotated(randf_range(-jitter, jitter)).normalized()

	## 将下一点位置设置为当前方向的100像素距离的点
	next_point = bullet.global_position + bullet.direction * 100

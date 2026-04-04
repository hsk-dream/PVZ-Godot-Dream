extends BulletMovementBase
class_name BulletMovementParabola
## 子弹移动组件 抛物线

## 控制抛物线的顶点高度 (调节上下弯曲的程度)
@export var parabola_height: float = -300
## 抛物线运行时敌人移动的最大距离, 敌人从瞄准时移动超过该值, 子弹不会进行修正
@export var max_diff_x: float = 200
## 敌人位置修正偏移值,更新敌人位置(终点)时，向上偏移20像素
@export var enemy_pos_corr_value:Vector2 =  Vector2(0, -20)

## 敌人移动距离(大于最大距离后,子弹不进行修正)
var curr_diff_x: float = 0

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

## 移动组件开始时参数，根ready调用
func parabola_movement_ready(end_glo_pos:Vector2=Vector2.ZERO):
	## 如果敌人还存在,更新敌人位置，不存在使用init时的位置
	end_global_pos = end_glo_pos + enemy_pos_corr_value

	curr_diff_x = 0
	curr_time = 0
	start_global_pos = bullet.global_position

	# 第一控制点 计算贝塞尔曲线的控制点，确保曲线的最高点位于中间
	start_control_point = Vector2(
		(start_global_pos.x + end_global_pos.x) / 2,
		# 确保最高点在路径的中间，调节 y 坐标来控制弯曲程度
		min(start_global_pos.y, end_global_pos.y) + parabola_height
	)
	## 第二控制点每帧更新，设置敌人上一次位置时更新
	second_control_point = end_global_pos + Vector2(0, -100)
	all_time = (start_control_point.distance_to(start_global_pos) + start_control_point.distance_to(end_global_pos)) / bullet.speed


## 设置敌人上一次（敌人死亡时，使用该位置）的全局位置
## 每帧根节点调用一次,超过最大移动时，不更新
func set_enemy_last_global_pos(target_enemy:Character000Base):
	## 计算敌人移动的水平差距
	curr_diff_x += abs(target_enemy.hurt_box_component.global_position.x - end_global_pos.x)
	if curr_diff_x < max_diff_x:
		end_global_pos = target_enemy.hurt_box_component.global_position + enemy_pos_corr_value
		end_global_pos = end_global_pos
		second_control_point = end_global_pos + Vector2(0, -100)

## 每物理帧移动一次, 根节点调用
## return [bool]: 是否更新位置成功，若到达最后，更新失败
func physics_process_bullet_move(delta: float) -> bool:
	curr_time += delta
	var t :float= min(curr_time / all_time, 1)
	## 使用缓动函数来调整时间 t (最后时移动变快)
	var eased_t = eased_time(t)

	#print("当前时间：", curr_time, " 最终比例：", t)
	## 如果到达最终落点时未命中敌人,移动失败，子弹根调用攻击null销毁子弹
	if eased_t >= 1:
		return false

	## 子弹根据贝塞尔曲线的路径更新位置
	bullet.global_position = start_global_pos.bezier_interpolate(start_control_point, second_control_point, end_global_pos, eased_t)

	return true

## 重置抛物线移动数据 被保护伞弹开时
func reset_parabola_movement_be_umbrella_bounce():
	## 原本的终点和起点的差值
	var ori_diff = end_global_pos - start_global_pos
	## 更新起点，终点、两个控制点
	start_global_pos = bullet.global_position
	end_global_pos = Vector2(end_global_pos.x +  ori_diff.x/2, end_global_pos.y)
	# 计算贝塞尔曲线的控制点，确保曲线的最高点位于中间
	start_control_point = Vector2(
		(start_global_pos.x + end_global_pos.x) / 2,
		# 确保最高点在路径的中间，调节 y 坐标来控制弯曲程度
		min(start_global_pos.y, end_global_pos.y) + parabola_height / 2
	)
	## 被弹开时，第二控制点=终点
	second_control_point = end_global_pos
	curr_time = 0
	all_time = (start_control_point.distance_to(start_global_pos) + start_control_point.distance_to(end_global_pos)) / bullet.speed

## 自定义的缓动函数，分段加速,抛物线移动到最后时加速
func eased_time(t: float) -> float:
	if t > 0.5:
		if (t-0.5) * 1.2 + 0.5 > 0.6:
			if ((t-0.5) * 1.2 + 0.5 - 0.6) * 1.3 + 0.6 > 0.9:
				return (((t-0.5) * 1.2 + 0.5 - 0.6) * 1.3 + 0.6 - 0.9) * 2 + 0.9
			return ((t-0.5) * 1.2 + 0.5 - 0.6) * 1.3 + 0.6
		return (t-0.5) * 1.2 + 0.5
	else:
		return t

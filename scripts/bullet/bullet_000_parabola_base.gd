extends Bullet000Base
class_name Bullet000ParabolaBase

## 抛物线运行的最大误差, 敌人从瞄准时移动超过该值, 子弹不会进行修正
@export var max_diff_x: float = 200
## 控制抛物线的顶点高度 (调节上下弯曲的程度)
@export var parabola_height: float = -300
## 抛物线(贝塞尔曲线)子弹需要根据敌人位置每帧更新(_ready之前赋值)
var target_enemy: Character000Base
## 敌人最终位置，敌人死亡时位置不变
var enemy_last_global_pos: Vector2
## 敌人移动距离(大于最大距离后,子弹不进行修正)
var curr_diff_x: float
## 贝塞尔曲线当前时间
var current_time = 0.0
## 贝塞尔曲线的控制点1
var start_control_point: Vector2
## 开始时全局位置
var start_global_pos:Vector2
## 子弹移动的总时间(控制点到起点和终点距离和/速度)
var all_time:float

#region 影子相关
## 当前场景是否有斜坡,有斜坡的场景每帧检测斜面位置
var is_have_slope:=false
## 影子全局位置y,
## 该值默认为当前行僵尸出现位置y
## 有斜面时更新该值,更新影子对应位置
var global_pos_y_shadow:float
#endregion

#region 被弹开
## 是否被弹开
var is_bounce:=false
## 是否弹开更新曲线
var is_bounce_update:=false
## 弹开的起点
var start_global_pos_on_bounce:Vector2
## 弹开的终点
var end_global_pos_on_bounce:Vector2
## 第一控制点
var start_control_point_on_bounce:Vector2
#endregion

func _ready() -> void:
	super()
	if is_instance_valid(target_enemy) and is_instance_valid(target_enemy.hurt_box_component):
		enemy_last_global_pos = target_enemy.hurt_box_component.global_position
	curr_diff_x = 0
	start_global_pos = global_position
	# 计算贝塞尔曲线的控制点，确保曲线的最高点位于中间
	start_control_point = Vector2(
		(global_position.x + enemy_last_global_pos.x) / 2,
		# 确保最高点在路径的中间，调节 y 坐标来控制弯曲程度
		min(global_position.y, enemy_last_global_pos.y) + parabola_height
	)
	all_time = (start_control_point.distance_to(global_position) + start_control_point.distance_to(enemy_last_global_pos)) / speed

	## 是否有斜坡
	is_have_slope = is_instance_valid(Global.main_game.main_game_slope)
	global_pos_y_shadow = Global.main_game.zombie_manager.all_zombie_rows[lane].zombie_create_position.global_position.y

	update_shadow_global_pos()


## 抛物线初始化子弹属性
## [Enemy: Character000Base]: 敌人
## [EnemyGloPos:Vector2]:敌人位置,发射单位赋值,若发射时敌人死亡,使用该位置
func init_bullet(bullet_paras:Dictionary[E_InitParasAttr,Variant]):
	super(bullet_paras)

	## 抛物线子弹初始化
	self.target_enemy = bullet_paras.get(E_InitParasAttr.Enemy, null)

	self.enemy_last_global_pos = bullet_paras[E_InitParasAttr.EnemyGloPos]


func _physics_process(delta: float) -> void:
	## 若敌人存在且敌人还未死亡,更新其位置
	if is_instance_valid(target_enemy) and not target_enemy.is_death:
		##$ 计算敌人移动的水平差距
		curr_diff_x += abs(target_enemy.hurt_box_component.global_position.x - enemy_last_global_pos.x)
		if curr_diff_x < max_diff_x:
			enemy_last_global_pos = target_enemy.hurt_box_component.global_position + Vector2(0, -20)

	current_time += delta
	var t :float= min(current_time / all_time, 1)
	#prints(current_time, all_time, t )
	## 使用缓动函数来调整时间 t (最后时移动变快)
	var eased_t = eased_time(t)
	## 如果到达最终落点时未命中敌人,攻击空气销毁子弹
	if eased_t >= 1:
		attack_once(null)
	## 是否更新弹开曲线
	if not is_bounce_update:
		## 子弹根据贝塞尔曲线的路径更新位置
		global_position = start_global_pos.bezier_interpolate(start_control_point, enemy_last_global_pos + Vector2(0, -100), enemy_last_global_pos, eased_t)
	else:
		## 子弹根据贝塞尔曲线的路径更新位置
		global_position = start_global_pos_on_bounce.bezier_interpolate(start_control_point_on_bounce, end_global_pos_on_bounce, end_global_pos_on_bounce, eased_t)

	update_shadow_global_pos()

	## 移动超过最大距离后销毁，部分子弹有限制
	if global_position.distance_to(start_pos) > max_distance:
		queue_free()

## 攻击一次
func attack_once(enemy:Character000Base):
	## 攻击植物时,若周围有叶子保护伞
	if enemy is Plant000Base:
		var all_umbrella_surrounding:Array[Plant000Base] = enemy.plant_cell.get_plant_surrounding(EnumsCharacter.PlantType.P038UmbrellaLeaf)
		if not all_umbrella_surrounding.is_empty():
			for p:Plant038UmbrellaLeaf in all_umbrella_surrounding:
				p.activete_umbrella()
			be_umbrella_bounce()
			return
	super(enemy)


## 控制影子位置
func update_shadow_global_pos():
	if is_have_slope:
		update_global_pos_y_shadow_on_have_slope()

	bullet_shadow.global_position.y = global_pos_y_shadow

## 场景有斜坡时更新默认影子y值
func update_global_pos_y_shadow_on_have_slope():
	## 获取相对斜坡的位置
	var slope_y = Global.main_game.main_game_slope.get_all_slope_y(global_position.x)
	global_pos_y_shadow = Global.main_game.zombie_manager.all_zombie_rows[lane].zombie_create_position.global_position.y + slope_y


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


## 抛物线子弹先对Norm进行攻击
func get_first_be_hit_plant_in_cell(plant:Plant000Base)->Plant000Base:
	## shell
	if is_instance_valid(plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]):
		return plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Norm]
	elif is_instance_valid(plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Shell]):
		return plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Shell]
	elif is_instance_valid(plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Down]):
		return plant.plant_cell.plant_in_cell[EnumsCharacter.PlacePlantInCell.Down]
	else:
		printerr("当前植物格子没有检测到可以攻击的植物")
		return null

## 被保护伞弹开,更新移动贝塞尔曲线
func be_umbrella_bounce():
	if not is_bounce:
		z_index = 4000
		is_bounce = true
		## 被弹开之后,删除子弹碰撞器
		area_2d_attack.queue_free()

		#await get_tree().create_timer(0.1).timeout
		is_bounce_update = true
		## 原本的终点和起点的差值
		var ori_diff = enemy_last_global_pos - start_global_pos
		## 被弹开后更新起点.终点,控制点位置
		start_global_pos_on_bounce = global_position
		end_global_pos_on_bounce = enemy_last_global_pos + ori_diff/2
		# 计算贝塞尔曲线的控制点，确保曲线的最高点位于中间
		start_control_point_on_bounce = Vector2(
			(start_global_pos_on_bounce.x + end_global_pos_on_bounce.x) / 2,
			# 确保最高点在路径的中间，调节 y 坐标来控制弯曲程度
			min(start_global_pos_on_bounce.y, end_global_pos_on_bounce.y) + parabola_height / 2
		)

		current_time = 0
		all_time = (start_control_point_on_bounce.distance_to(start_global_pos_on_bounce) + start_control_point_on_bounce.distance_to(end_global_pos_on_bounce)) / speed

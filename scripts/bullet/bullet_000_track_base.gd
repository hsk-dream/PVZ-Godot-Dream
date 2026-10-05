extends Bullet000NormBase
class_name Bullet000TrackBase

@onready var movement_component: BulletMovementTrack = $MovementComponent

## 当前追踪目标；跨帧缓存，角色释放后引用不会自动清空。
var target_enemy:Character000Base = null
## 全局检测组件
var detect_component_global:DetectComponent

func _ready() -> void:
	super()
	# 已释放对象无法传入强类型参数，必须在调用资格检查前短路排除。
	if not is_instance_valid(target_enemy) or not _can_attack_character(target_enemy, false):
		target_enemy = detect_component_global.update_enemy_track_bullet()

## 追踪子弹初始化子弹属性
## [Enemy: Character000Base]: 敌人
func init_bullet(bullet_paras:Dictionary[E_InitParasAttr,Variant]):
	super(bullet_paras)
	z_index = 4000
	detect_component_global = Global.main_game.detect_component_global

	target_enemy = bullet_paras.get(E_InitParasAttr.Enemy, null)


func _physics_process(delta: float) -> void:
	# 目标被释放、死亡或暂时关闭受击时重新索敌；有效性检查须先于强类型调用。
	if is_instance_valid(target_enemy) and _can_attack_character(target_enemy, false):
		movement_component.reset_track_movement(true, false, target_enemy.hurt_box_component.global_position)
	## 敌人不存在 全局寻找敌人
	else:
		if is_instance_valid(detect_component_global.enemy_can_be_attacked) \
			and _can_attack_character(detect_component_global.enemy_can_be_attacked, false):
			target_enemy = detect_component_global.enemy_can_be_attacked
		else:
			target_enemy = detect_component_global.update_enemy_track_bullet()
		## 如果找到敌人
		if is_instance_valid(target_enemy) and _can_attack_character(target_enemy, false):
			movement_component.reset_track_movement(true, true, target_enemy.hurt_box_component.global_position)
			## 已在目标受击盒内时不会再次触发 area_entered（例如刚切换目标时子弹已在箱内），用重叠补判
			_try_attack_target_if_already_overlapping()

		## 如果没找到敌人
		else:
			movement_component.reset_track_movement(false)

	movement_component.physics_process_bullet_move(delta)

	## 移动超过最大距离后销毁，部分子弹有限制,大部分子弹超过默认2000后删除
	if global_position.distance_to(start_pos) > max_distance:
		queue_free()

## 切换目标时，尝试攻击是否已经碰撞
func _try_attack_target_if_already_overlapping() -> void:
	if not is_instance_valid(target_enemy) or not _can_attack_character(target_enemy, false):
		return
	## 无限穿透仍依赖多次 area_entered；若在此每帧补判会连续造成伤害
	if max_attack_num == -1:
		return
	if curr_attack_num >= max_attack_num:
		return
	for a: Area2D in area_2d_attack.get_overlapping_areas():
		if a.owner == target_enemy:
			attack_once(target_enemy)
			return


## 子弹与敌人碰撞
func _on_area_2d_attack_area_entered(area: Area2D) -> void:
	# 区域关闭存在物理帧延迟，入口仍须同步检查受击开关和阵营。
	if not is_instance_valid(target_enemy) or area.owner != target_enemy or not _can_attack_character(target_enemy, false):
		return
	if max_attack_num == -1 or curr_attack_num < max_attack_num:
		attack_once(target_enemy)

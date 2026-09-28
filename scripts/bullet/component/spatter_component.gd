extends Node2D
class_name SpatterComponent
## 子弹溅射伤害组件

## 实际溅射区域，以重叠受击框限定伤害范围。
@onready var area_2d_spatter: Area2D = $Area2DSpatter

## 总溅射伤害
@export var sum_attack_value:int=40
## 溅射伤害范围
@export var range_attack_value:Vector2i=Vector2i(1, 13)
## 溅射到的上下行,默认为-1,无关行属性
@export var spatter_lane_up_down := -1
@export_group("攻击相关")
## 可以攻击的敌人状态
@export_flags("1 正常", "2 悬浮", "4 地刺", "8 低矮") var can_attack_plant_status:int = 9
## 允许溅射的普通僵尸状态；僵王按正常状态处理。
@export_flags("1 正常", "2 跳跃", "4 水下", "8 空中", "16 地下") var can_attack_zombie_status:int = 1

## [param direct_hit_enemy] 本次直击目标，不再分摊溅射；可为空，表示子弹落空后溅射。[br]
## [param lane] 弹道行，-1 表示不限制行。先筛选、去重，再按实际候选角色数量分摊伤害。
func spatter_all_area_zombie(direct_hit_enemy:Character000Base, lane:int=-1):
	# 保留 Variant 引用，避免结算期间其他目标被释放后发生类型赋值错误。
	var targets: Array = []
	# 同一角色的多个受击框只占一个分摊名额。
	var seen_ids: Dictionary[int, bool] = {}
	# 溅射依然以实际重叠范围为准。
	for area: Area2D in area_2d_spatter.get_overlapping_areas():
		# 非角色区域会转换为空并在目标检查中跳过。
		var enemy := area.owner as Character000Base
		if enemy == direct_hit_enemy or not _can_spatter_character(enemy, lane):
			continue
		# 当前角色的唯一编号，用于区域去重。
		var instance_id: int = enemy.get_instance_id()
		if not seen_ids.has(instance_id):
			seen_ids[instance_id] = true
			targets.append(enemy)
	if targets.is_empty():
		return
	# 本轮伤害取筛选完成时的目标数量，结算中的死亡不会重新分配已发出的伤害。
	var damage_per_enemy: int = clampi(int(float(sum_attack_value) / targets.size()), range_attack_value.x, range_attack_value.y)
	# 前一个目标的死亡可能释放或改变后续目标，执行前再次检查。
	for target_reference: Variant in targets:
		if not is_instance_valid(target_reference):
			continue
		# 仅有效引用才转换为角色类型。
		var enemy := target_reference as Character000Base
		if _can_spatter_character(enemy, lane):
			attack_enemy(enemy, damage_per_enemy)


## [param enemy] 已重叠的角色；[param lane] 弹道行。返回有效受击目标，僵王不比较根节点行号。
func _can_spatter_character(enemy: Character000Base, lane: int) -> bool:
	if not is_instance_valid(enemy) or enemy.is_death or enemy.is_queued_for_deletion() \
		or not enemy.is_inside_tree() or not is_instance_valid(enemy.hurt_box_component) \
		or not enemy.hurt_box_component.is_enabling:
		return false
	if enemy is ZB000Base:
		return enemy.character_init_type == Character000Base.E_CharacterInitType.IsNorm \
			and (can_attack_zombie_status & Zombie000Base.E_BeAttackStatusZombie.IsNorm) != 0
	if enemy is Plant000Base:
		if (enemy.curr_be_attack_status & can_attack_plant_status) == 0:
			return false
	elif enemy is Zombie000Base:
		if (enemy.curr_be_attack_status & can_attack_zombie_status) == 0:
			return false
	else:
		return false
	return spatter_lane_up_down == -1 or lane == -1 or absi(lane - enemy.lane) <= spatter_lane_up_down

## [param enemy] 已通过筛选的目标；[param damage_per_enemy] 本次分摊伤害，不包含直接命中伤害。
func attack_enemy(enemy:Character000Base, damage_per_enemy:int):
	enemy.be_attacked_bullet(damage_per_enemy,BulletRegistry.AttackMode.Penetration, true, false)

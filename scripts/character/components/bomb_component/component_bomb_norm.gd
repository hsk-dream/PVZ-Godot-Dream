extends BombComponentBase
class_name BombComponentNorm
## 普通炸弹使用爆炸组件

## 爆炸表现，与伤害筛选独立触发。
@onready var bomb_effect: BombEffectBase = $BombEffect

## 爆炸特效
func _start_bomb_fx():
	bomb_effect.activate_bomb_effect()

## 收集范围内的有效敌人并按角色去重；僵王跨行由受击区域决定，致死后保留死亡演出。
func _bomb_all_enemy():
	# 保存未转换的引用，前一个目标的死亡回调可能释放后续目标。
	var targets: Array = []
	# 同一角色可能有多个受击区域，一次爆炸只登记一次。
	var seen_ids: Dictionary[int, bool] = {}
	# 爆炸实际覆盖的受击区域；范围外的僵王不会被全场命中。
	for area: Area2D in area_2d_bomb.get_overlapping_areas():
		# 区域所属对象，梯子继续沿用原有销毁规则。
		var area_owner: Node = area.owner
		if area_owner is Ladder:
			if bomb_lane == -1 or absi(owner.lane - area_owner.lane) <= bomb_lane:
				area_owner.ladder_death()
		elif area_owner is Character000Base and _can_bomb_character(area_owner):
			# 用实例编号去重，不将区域数量当作敌人数量。
			var instance_id: int = area_owner.get_instance_id()
			if not seen_ids.has(instance_id):
				seen_ids[instance_id] = true
				targets.append(area_owner)
	# 每次结算前重新检查存活与受击状态，抵御同步死亡回调和延迟禁用碰撞。
	for target_reference: Variant in targets:
		if not is_instance_valid(target_reference):
			continue
		# 通过引用检查后才转换为角色。
		var target := target_reference as Character000Base
		if not _can_bomb_character(target):
			continue
		if target is ZB000Base:
			target.be_attacked_bullet(bomb_value, BulletRegistry.AttackMode.Penetration, false, false)
		elif target is Zombie000Base:
			target.be_bomb(bomb_value, is_cherry_bomb)


## [param enemy] 已与爆炸区域重叠的角色；返回是否可结算伤害，不扩大爆炸范围。
func _can_bomb_character(enemy: Character000Base) -> bool:
	if not is_instance_valid(enemy) or enemy.is_death or enemy.is_queued_for_deletion() \
		or not enemy.is_inside_tree():
		return false
	if enemy is ZB000Base:
		return enemy.character_init_type == Character000Base.E_CharacterInitType.IsNorm \
			and is_instance_valid(enemy.hurt_box_component) and enemy.hurt_box_component.is_enabling \
			and (can_attack_zombie_status & Zombie000Base.E_BeAttackStatusZombie.IsNorm) != 0
	return enemy is Zombie000Base and (enemy.curr_be_attack_status & can_attack_zombie_status) != 0 \
		and judge_lane(enemy)


## [param enemy] 普通角色；返回是否处于配置的爆炸行范围，-1 表示不限制行。
func judge_lane(enemy:Character000Base) -> bool:
	return bomb_lane == -1 or (owner.lane + bomb_lane >= enemy.lane and owner.lane - bomb_lane <= enemy.lane )

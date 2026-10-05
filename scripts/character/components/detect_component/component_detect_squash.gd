extends DetectComponent
class_name DetectComponentSquash

## 部分僵尸有需要进行倭瓜位置判断,撑杆跳起跳之前在左边时可以攻击


## 判断敌人状态是否可以被攻击
func _judge_enemy_is_can_be_attack(enemy:Character000Base)->bool:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.is_death:
		return false
	# 僵王沿用通用受击开关和跨行判断，不套用撑杆、海豚的落点规则。
	if enemy is ZB000Base:
		return super._judge_enemy_is_can_be_attack(enemy)
	## 先判断行属性
	if is_lane and owner.lane != enemy.lane:
		return false
	## 如果敌人为植物
	if enemy is Plant000Base:
		## 如果当前植物可以被攻击到
		if enemy.curr_be_attack_status & can_attack_plant_status:
			## 梯子
			if is_attack_ladder_plant:
				return true
			else:
				## 判断格子是否有梯子
				return not is_instance_valid(enemy.plant_cell.ladder)
		else:
			return false

	## 检测到僵尸
	elif enemy is Zombie000Base:
		if enemy.curr_be_attack_status & can_attack_zombie_status:
			## 如果触发倭瓜位置判定（撑杆跳、海豚僵尸）
			if enemy.is_trigger_squash_pos_judge:
				## 敌人在左边
				if enemy.global_position.x < owner.global_position.x:
					enemy_can_be_attacked = enemy
					return true
				else:
					return false
			else:
				enemy_can_be_attacked = enemy
				return true
		else:
			return false
	## 其余东西
	else:
		print("检测到非角色类敌人")
		return false

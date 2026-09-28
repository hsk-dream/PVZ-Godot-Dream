extends SpatterComponent
class_name SpatterComponentWinterMelon

## 冰西瓜传入的减速持续时间，单位为秒。
var time_be_decelerated :float = 3.0


## [param enemy] 有效溅射目标；[param damage_per_enemy] 分摊伤害。致死后不追加减速或冰色。
func attack_enemy(enemy:Character000Base, damage_per_enemy:int):
	super.attack_enemy(enemy, damage_per_enemy)
	if is_instance_valid(enemy) and _can_spatter_character(enemy, -1):
		enemy.be_ice_decelerate(time_be_decelerated)

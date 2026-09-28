extends BulletLinear000Base
class_name Bullet002PeaSnow

## 命中后的减速持续秒数；普通僵尸的二类防具仍可阻挡减速。
@export var time_be_decelerated :float = 3.0

## [param enemy] 已由子弹基类确认的命中目标；致死、落空或受击关闭时不追加减速。
func _attack_enemy(enemy:Character000Base):
	super(enemy)
	if not is_instance_valid(enemy) or not _can_attack_character(enemy):
		return
	if enemy is ZB000Base:
		enemy.be_ice_decelerate(time_be_decelerated)
	elif enemy is Zombie000Base and enemy.hp_component.curr_hp_armor2 <= 0:
		enemy.be_ice_decelerate(time_be_decelerated)



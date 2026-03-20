extends SpatterComponent
class_name SpatterComponentWinterMelon

var time_be_decelerated :float = 3.0


func attack_enemy(enemy:Character000Base, damage_per_enemy:int):
	enemy.be_attacked_bullet(damage_per_enemy, EnumsBullet.AttackMode.Penetration, true, false)
	enemy.be_ice_decelerate(time_be_decelerated)

extends Bullet000ParabolaBase

## 普通僵尸被黄油定身的秒数；僵王只承受黄油伤害，不受定身影响。
@export var butter_time:float = 4.0

## [param enemy] 已确认的命中目标；仅仍存活的普通僵尸添加黄油，僵王不访问普通僵尸头部节点。
func _attack_enemy(enemy:Character000Base):
	super(enemy)
	if is_instance_valid(enemy) and _can_attack_character(enemy) and enemy is Zombie000Base:
		enemy.be_butter(butter_time)

extends BulletLinear000Base
class_name Bullet1003BowlingBig

## 坚果旋转表现节点。
@onready var body_correct: Node2D = $Body/BodyCorrect
## 僵王承受的单次穿透伤害，避免普通僵尸的秒杀规则直接清空僵王血量。
@export_range(0, 10000, 1, "or_greater") var boss_attack_value: int = 1800

## 旋转速度
var rotation_speed = 5.0


func _physics_process(delta: float) -> void:
	super(delta)
	body_correct.rotation += rotation_speed * delta

## [param enemy] 基类确认的命中目标；僵王按固定伤害结算，普通角色保留秒杀，落空则忽略。
func _attack_enemy(enemy:Character000Base):
	if enemy is ZB000Base:
		enemy.be_attacked_bullet(boss_attack_value, BulletRegistry.AttackMode.Penetration, true, trigger_be_attack_sfx)
	elif is_instance_valid(enemy):
		enemy.be_attack_to_death(trigger_be_attack_sfx)
